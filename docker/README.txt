This explains how the biodsl docker image is build and pushed to dockerhub:

Do replace tag appropriately (git describe --abbrev=0 --tags).

# build biodsl docker image
docker build -t maasha/biodsl:v1.0.3 .

# interactive login to dockerhub
docker login

# push biodsl docker image to dockerhub
docker push maasha/biodsl:v1.0.3
