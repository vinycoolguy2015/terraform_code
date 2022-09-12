version: 0.2
phases:
  install:
    runtime-versions:
      docker: 18
  build:
    commands:
     - ls -ltra
     - "printf 'version: 0.0\nResources:\n  - TargetService:\n      Type: AWS::ECS::Service\n      Properties:\n        TaskDefinition: <TASK_DEFINITION>\n        LoadBalancerInfo:\n          ContainerName: \"${container_name}\"\n          ContainerPort: ${container_port}' > appspec.yaml"
     - cat appspec.yaml
     - aws ecs describe-task-definition --output json --task-definition ${task_definition} --query taskDefinition > template.json
     - jq '.containerDefinitions | map((select(.name == "${container_name}") | .image) |= "<IMAGE1_NAME>") | {"containerDefinitions":.}' template.json > template2.json
     - jq -s '.[0] * .[1]' template.json template2.json > taskdef.json
     - cat taskdef.json
     - cat imageDetail.json
artifacts:
    files:
    - imageDetail.json
    - appspec.yaml
    - taskdef.json
