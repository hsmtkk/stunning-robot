# 前提条件
- Google Cloudのアカウントを持っている。

# Google Cloudのプロジェクト作成
- production, develop
- developでCloud Shell起動
- 以降、developのCloud Shellで作業する
- export DEVELOP_ID=
- export PRODUCT_ID=

# サービス有効化
- enable-service.sh

# GitHubのレポジトリ準備
- GitHubにレポジトリ作成
- クローン
- production, developブランチ作成
- production, developブランチ push
- GitHubでdevelopをデフォルトブランチにセット
- 以降、developブランチで作業

# Goアプリ作成
- go mod init
- web.go作成
- go mod tidy
- go run .

# Docker
- Dockerfile作成
- docker build --tag web .
- docker run --publish 8080:8080 web

# Artifact Registry
- gcloud artifacts repositories create registry --location=us-central1 --repository-format=docker

# Cloud Build
- GUIでCloudRun権限付与
- cloudbuild1.yaml作成
- gcloud builds submit --config=cloudbuild1.yaml

# Cloud Run
- gcloud run deploy web --allow-unauthenticated --execution-environment=gen2 --image=us-central1-docker.pkg.dev/${DEVELOP_ID}/registry/web:latest --region=us-central1

# docker build～Cloud Run一気
- cloudbuild2.yaml
- gcloud builds submit --config=cloudbuild2.yaml

# GitHub push時にCloud Build
- Cloud Build GUIでGitHub接続
- cloudbuild-develop-push.yaml

gcloud builds triggers create github --branch-pattern="^develop$" --build-config=cloudbuild-develop-push.yaml --repo-name=stunning-robot --repo-owner=hsmtkk --name=develop-push

https://cloud.google.com/sdk/gcloud/reference/beta/builds/triggers/create/github

- dummy push
git commit --allow-empty -m trigger
git push

# test
- web_test.go
- cloudbuild-production-pull-request.yaml

gcloud builds triggers create github --pull-request-pattern="^production$" --comment-control=COMMENTS_DISABLED --build-config=cloudbuild-production-pull-request.yaml --repo-name=stunning-robot --repo-owner=hsmtkk --name=production-pull-request

# GitHub pull request作成
- branch protection rule作成 Require status checks to pass before merging, Do not allow bypass
  Status checks that are required => production-pull-request

# 修正、再push

# production deploy manually
gcloud config set project $PRODUCTION_ID
gcloud run deploy web --allow-unauthenticated --execution-environment=gen2 --image=us-central1-docker.pkg.dev/${DEVELOP_ID}/registry/web:latest --region=us-central1

```
ERROR: (gcloud.run.deploy) Google Cloud Run Service Agent service-989728667853@serverless-robot-prod.iam.gserviceaccount.com must have permission to read the image, us-central1-docker.pkg.dev/develop-381422/registry/web:latest. Ensure that the provided container image URL is correct and that the above account has permission to access the image. If you just enabled the Cloud Run API, the permissions might take a few minutes to propagate. Note that the image is from project [develop-381422], which is not the same as this project [production-381422]. Permission must be granted to the Google Cloud Run Service Agent service-989728667853@serverless-robot-prod.iam.gserviceaccount.com from this project.
```

gcloud projects add-iam-policy-binding $DEVELOP_ID --member=serviceAccount:service-989728667853@serverless-robot-prod.iam.gserviceaccount.com --role=roles/artifactregistry.reader

# production deploy with cloud build
- cloudbuild-production-push.yaml
gcloud config set project $PRODUCTION_ID

gcloud builds triggers create github --branch-pattern="^production$" --build-config=cloudbuild-production-push.yaml --repo-name=stunning-robot --repo-owner=hsmtkk --name=production-push
