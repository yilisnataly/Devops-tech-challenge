set -e

AWS_REGION=${AWS_REGION}
ECR_REPOSITORY=${ECR_REPOSITORY}
CLUSTER_NAME=${CLUSTER_NAME}
SERVICE_NAME=${SERVICE_NAME}
ECS_TASK_DEFINITION=${ECS_TASK_DEFINITION}
AWS_SUBNETS=${AWS_SUBNETS}
AWS_SECURITY_GROUPS=${AWS_SECURITY_GROUPS}

# Validación de secrets
if [ -z "$AWS_SUBNETS" ] || [ -z "$AWS_SECURITY_GROUPS" ]; then
  echo "ERROR: Debes definir AWS_SUBNETS y AWS_SECURITY_GROUPS como secrets en GitHub"
  exit 1
fi

# Limpiar posibles espacios
AWS_SUBNETS=$(echo "$AWS_SUBNETS" | xargs)
AWS_SECURITY_GROUPS=$(echo "$AWS_SECURITY_GROUPS" | xargs)

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

    # Limpiar ARN de saltos de línea
    ECS_TASK_DEFINITION_ARN=$(echo "$ECS_TASK_DEFINITION_ARN" | tr -d '\n' | tr -d '\r')
    echo "Task definition registrada: $ECS_TASK_DEFINITION_ARN"

    # Esperar propagación
    echo "Esperando 5 segundos para propagación de la task definition..."
    sleep 5

    echo "Generar NETWORK_CONFIG seguro con jq"
    SUBNETS_JSON=$(jq -R -s -c 'split(",")' <<< "$AWS_SUBNETS")
    SG_JSON=$(jq -R -s -c 'split(",")' <<< "$AWS_SECURITY_GROUPS")
    NETWORK_CONFIG=$(jq -n \
      --argjson subnets "$SUBNETS_JSON" \
      --argjson sgs "$SG_JSON" \
      '{awsvpcConfiguration: {subnets: $subnets, securityGroups: $sgs, assignPublicIp: "ENABLED"}}')

    # Verificar servicio ECS
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

