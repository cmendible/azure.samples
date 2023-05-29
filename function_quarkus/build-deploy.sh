#!/usr/bin/env bash
set -eu

pushd .
cd quarkus-http-custom-handler/
./mvnw clean package -Pnative -Dquarkus.native.container-build=true \
  -Dquarkus.native.builder-image=quay.io/quarkus/ubi-quarkus-mandrel-builder-image:22.3.2.1-Final-java17
popd

cp quarkus-http-custom-handler/target/*-runner function/quarkus-handler

pushd .
cd infra/
terraform init
terraform apply -auto-approve
FUNCTION_NAME=$(terraform output -raw function_name)
popd

pushd .
cd function/
func azure functionapp publish $FUNCTION_NAME
popd
