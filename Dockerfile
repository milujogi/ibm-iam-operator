#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Build the manager binary
FROM golang:1.21.8-bullseye as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY apis/ apis/
COPY controllers/ controllers/

# Build
# the GOARCH has not a default value to allow the binary be built according to the host where the command
# was called. For example, if we call make docker-build in a local env which has the Apple Silicon M1 SO
# the docker BUILDPLATFORM arg will be linux/arm64 when for Apple x86 it will be linux/amd64. Therefore,
# by leaving it empty we can ensure that the container and binary shipped on it will have the same platform.
RUN CGO_ENABLED=0 GOOS=linux go build -a -o manager main.go

# Swap default image for ubi8-minimal
FROM docker-na-public.artifactory.swg-devops.com/hyc-cloud-private-edge-docker-local/build-images/ubi8-minimal:latest

ARG VCS_REF
ARG VCS_URL

LABEL org.label-schema.vendor="IBM" \
    org.label-schema.name="ibm-iam-operator" \
    org.label-schema.description="IBM IAM Operator" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.license="Licensed Materials - Property of IBM" \
    org.label-schema.schema-version="1.0" \
    name="ibm-iam-operator" \
    vendor="IBM" \
    description="IBM IM Operator" \
    summary="IBM IM Operator"

ENV OPERATOR=/usr/local/bin/ibm-iam-operator \
    USER_UID=1001 \
    USER_NAME=ibm-iam-operator

WORKDIR /
COPY --from=builder /workspace/manager ${OPERATOR}

# Copy in licenses
RUN mkdir /licenses
COPY LICENSE /licenses

USER ${USER_UID}

ENTRYPOINT ["/usr/local/bin/ibm-iam-operator"]
