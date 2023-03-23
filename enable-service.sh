#!/bin/sh
for project in $PRODUCTION_ID $DEVELOP_ID
do
    gcloud config set project $project
    gcloud services enable artifactregistry.googleapis.com cloudbuild.googleapis.com run.googleapis.com
done
