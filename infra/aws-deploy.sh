set -e

AWS_REGION=${AWS_REGION}
ECR_REPOSITORY=${ECR_REPOSITORY}
CLUSTER_NAME=${CLUSTER_NAME}
SERVICE_NAME=${SERVICE_NAME}
ECS_TASK_DEFINITION=${ECS_TASK_DEFINITION}
AWS_SUBNETS=${AWS_SUBNETS}
AWS_SECURITY_GROUPS=${AWS_SECURITY_GROUPS}

case "$1" in
  setup)
    echo "[SETUP] Creando/validando recursos básicos en AWS"

    echo "Verificando repositorio ECR..."
    aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION

    echo "Verificando cluster ECS..."
    aws ecs describe-clusters --clusters $CLUSTER_NAME --region $AWS_REGION | grep "ACTIVE" >/dev/null 2>&1 || \
    aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $AWS_REGION

    echo "Recursos básicos listos en AWS"
    ;;

  deploy)
    echo "[DEPLOY] Registrando definición de tarea y actualizando servicio ECS..."

    echo "Registrando definición de tarea..."
    ECS_TASK_DEFINITION_ARN=$(aws ecs register-task-definition \
      --cli-input-json file://infra/ecs-task-def.json \
      --region "$AWS_REGION" \
      --query 'taskDefinition.taskDefinitionArn' \
      --output text) || { echo "Error registrando la task definition"; exit 1; }

    NETWORK_CONFIG="awsvpcConfiguration={subnets=[${AWS_SUBNETS}],securityGroups=[${AWS_SECURITY_GROUPS}],assignPublicIp=ENABLED}"

    echo " Verificar servicio ECS"
    SERVICE_STATUS=$(aws ecs describe-services \
      --cluster "$CLUSTER_NAME" \
      --services "$SERVICE_NAME" \
      --region "$AWS_REGION" \
      --query "services[0].status" \
      --output text 2>/dev/null || echo "NONE")

    if [ "$SERVICE_STATUS" == "ACTIVE" ]; then
      echo "Servicio existe, actualizando..."
      aws ecs update-service \
         --cluster "$CLUSTER_NAME" \
         --service "$SERVICE_NAME" \
         --task-definition "$ECS_TASK_DEFINITION_ARN" \
         --force-new-deployment \
         --region "$AWS_REGION"
    else
      echo "Servicio no existe, creándolo..."
      aws ecs create-service \
         --cluster "$CLUSTER_NAME" \
         --service-name "$SERVICE_NAME" \
         --task-definition "$ECS_TASK_DEFINITION_ARN" \
         --desired-count 1 \
         --launch-type FARGATE \
         --network-configuration "$NETWORK_CONFIG" \
         --region "$AWS_REGION"
    fi

    echo " Despliegue completado"
    ;;
 
esac

