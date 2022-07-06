## Go & Vue.js - Demo Web Application

This is a simple web application with a Go server/backend and a Vue.js SPA (Single Page Application) frontend.

The app has been designed with cloud native demos & containers in mind, in order to provide a real working application for deployment, something more than "hello-world" but with the minimum of pre-reqs. It is not intended as a complete example of a fully functioning architecture or complex software design.

Typical uses would be deployment to Kubernetes, demos of Docker, CI/CD (build pipelines are provided), deployment to cloud (AWS) monitoring, auto-scaling

- The Frontend is a SPA written in Vue.js 3. It uses [Bootstrap 5](https://getbootstrap.com/) and [Font Awesome](https://fontawesome.com/). In addition [Gauge.js](http://bernii.github.io/gauge.js/) is used for the dials in the monitoring view
- The Go component is a Go HTTP server based on the std http package and using [gopsutils](https://github.com/shirou/gopsutil) for monitoring metrics, and [Gorilla Mux](https://github.com/gorilla/mux) for routing

Features:

- System status / information view
- Geolocated weather info (from OpenWeather API)
- Realtime monitoring and metric view
- (Coming soon) Support for user authentication with Cognito
- Prometheus metrics
- API for generating CPU load, and allocating memory

<a href="https://user-images.githubusercontent.com/14982936/142773574-dbe9e623-001a-404d-a871-2e1151f67d01.png"><img style="width:410px" src="https://user-images.githubusercontent.com/14982936/142773574-dbe9e623-001a-404d-a871-2e1151f67d01.png"/></a>
<a href="https://user-images.githubusercontent.com/14982936/142773575-28d7dbf2-001e-48cc-a9b0-0b6c96f95be2.png"><img style="width:410px" src="https://user-images.githubusercontent.com/14982936/142773575-28d7dbf2-001e-48cc-a9b0-0b6c96f95be2.png"/></a>
<a href="https://user-images.githubusercontent.com/14982936/142773576-8f5abb5f-880a-408d-9a2b-ea3d2792378a.png"><img style="width:410px" src="https://user-images.githubusercontent.com/14982936/142773576-8f5abb5f-880a-408d-9a2b-ea3d2792378a.png"/></a>
<a href="https://user-images.githubusercontent.com/14982936/142773577-2e460ccd-b935-40bb-a41f-1f7a72e943bd.png"><img style="width:410px" src="https://user-images.githubusercontent.com/14982936/142773577-2e460ccd-b935-40bb-a41f-1f7a72e943bd.png"/></a>

# Status

![](https://img.shields.io/github/last-commit/benc-uk/vuego-demoapp) ![](https://img.shields.io/github/release-date/benc-uk/vuego-demoapp) ![](https://img.shields.io/github/v/release/benc-uk/vuego-demoapp) ![](https://img.shields.io/github/commit-activity/y/benc-uk/vuego-demoapp)

Live instance:

[![](https://img.shields.io/website?label=Hosted%3A%20Kubernetes&up_message=online&url=https%3A%2F%2Fvuego-demoapp.kube.benco.io%2F)](https://vuego-demoapp.kube.benco.io/)

## Repo Structure

```txt
/
├── frontend         Root of the Vue.js project
│   └── src          Vue.js source code
│   └── tests        Unit tests
├── deploy           Supporting files for AWS deployment etc
│   └── kubernetes   Instructions for Kubernetes deployment with Helm
├── server           Go backend server
│   └── cmd          Server main / exec
│   └── pkg          Supporting packages
├── build            Supporting build scripts and Dockerfile
└── test             API / integration tests
```

## Server API

The Go server component performs two tasks

- Serve the Vue.js app to the user. As this is a SPA, this is static content, i.e. HTML, JS & CSS files and any images. Note. The Vue.js app needs to be 'built' before it can be served, this bundles everything up correctly.
- Provide a simple REST API for data to be displayed & rendered by the Vue.js app. This API is very simple currently has three routes:
  - `GET /api/info` - Returns system information and various properties as JSON
  - `GET /api/monitor` - Returns monitoring metrics for CPU, memory, disk and network. This data comes from the _gopsutils_ library
  - `GET /api/weather/{lat}/{long}` - Returns weather data from OpenWeather API
  - `GET /api/gc` - Force the garbage collector to run
  - `POST /api/alloc` - Allocate a lump of memory, payload `{"size":int}`
  - `POST /api/cpu` - Force CPU load, payload `{"seconds":int}`

In addition to these application specific endpoints, the following REST operations are supported:

- `GET /api/status` - Status and information about the service
- `GET /api/health` - A health endpoint, returns HTTP 200 when OK
- `GET /api/metrics` - Returns low level system and HTTP performance metrics for scraping with Prometheus

## Building & Running Locally

### Pre-reqs

- Be using Linux, WSL or MacOS, with bash, make etc
- [Node.js](https://nodejs.org/en/) [Go 1.16+](https://golang.org/doc/install) - for running locally, linting, running tests etc
- [cosmtrek/air](https://github.com/cosmtrek/air#go) - if using `make watch-server`
- [Docker](https://docs.docker.com/get-docker/) - for running as a container, or image build and push
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) - for deployment to AWS

Clone the project to any directory where you do development work

```
git clone https://github.com/benc-uk/vuego-demoapp.git
```

### Makefile

A standard GNU Make file is provided to help with running and building locally.

```text
help                 💬 This help message
lint                 🔎 Lint & format, will not fix but sets exit code on error
lint-fix             📜 Lint & format, will try to fix errors and modify code
image                🔨 Build container image from Dockerfile
push                 📤 Push container image to registry
run                  🏃 Run BOTH components locally using Vue CLI and Go server backend
watch-server         👀 Run API server with hot reload file watcher, needs cosmtrek/air
watch-frontend       👀 Run frontend with hot reload file watcher
build-frontend       🧰 Build and bundle the frontend into dist
deploy               🚀 Deploy to Amazon ECS
undeploy             💀 Remove from AWS
test                 🎯 Unit tests for server and frontend
test-report          📜 Unit tests for server and frontend with report
test-snapshot        📷 Update snapshots for frontend tests
test-api             🚦 Run integration API tests, server must be running
clean                🧹 Clean up project
```

Make file variables and default values, pass these in when calling `make`, e.g. `make image IMAGE_REPO=blah/foo`


| Makefile Variable | Default                |
| ----------------- | ---------------------- |
| IMAGE_REG         | _none_                 |
| IMAGE_REPO        | vuego-demoapp           |
| IMAGE_TAG         | latest                 |
| AWS_STACK_NAME    | vuego-demoapp           |
| AWS_REGION        | us-west-2              |

- The server will listen on port 4000 by default, change this by setting the environmental variable `PORT`
- The server will ry to serve static content (i.e. bundled frontend) from the same directory as the server binary, change this by setting the environmental variable `CONTENT_DIR`
- The frontend will use `/api` as the API endpoint, when working locally `VUE_APP_API_ENDPOINT` is set and overrides this to be `http://localhost:4000/api`

# Containers

Public container image is [available on GitHub Container Registry](https://github.com/users/benc-uk/packages/container/package/vuego-demoapp)

Run in a container with:

```bash
docker run --rm -it -p 4000:4000 ghcr.io/benc-uk/vuego-demoapp:latest
```

Should you want to build your own container, use `make image` and the above variables to customise the name & tag.

## Kubernetes

The app can easily be deployed to Kubernetes using Helm, see [deploy/kubernetes/readme.md](deploy/kubernetes/readme.md) for details

## Running in Amazon ECS (Linux)

For a super quick deployment, use `make deploy` which will deploy via an AWS CloudFormation stack.

```bash
make deploy
```

# Config

Environmental variables

- `WEATHER_API_KEY` - Enable the weather feature with a OpenWeather API key
- `PORT` - Port to listen on (default: `4000`)
- `CONTENT_DIR` - Directory to serve static content from (default: `.`)
- `COGNITO_IDENTITY_POOL_ID` - (TODO) Set to a Amazon Cognito Identity Pool ID if you wish to enable the optional user sign-in feature

### User Authentication with Amazon Cognito

🚧 Coming soon.

# GitHub Actions CI/CD

A set of GitHub Actions workflows are included for CI / CD. Automated builds for PRs are run in GitHub hosted runners validating the code (linting and tests) and building dev images. When code is merged into master, then automated deployment to AKS is done using Helm.


[![](https://img.shields.io/github/workflow/status/benc-uk/vuego-demoapp/CI%20Build%20App)](https://github.com/benc-uk/vuego-demoapp/actions?query=workflow%3A%22CI+Build+App%22) [![](https://img.shields.io/github/workflow/status/benc-uk/vuego-demoapp/CD%20Release%20-%20AKS?label=release-kubernetes)](https://github.com/benc-uk/vuego-demoapp/actions?query=workflow%3A%22CD+Release+-+AKS%22)

## Updates

| When       | What                                                 |
| ---------- | ---------------------------------------------------- |
| Jul 2022   | Update for AWS (Michael Fischer)                     |
| Nov 2021   | Rewrite for Vue.js 3, new look & feel, huge refactor |
| Mar 2021   | Auth using MSAL.js v2 added                          |
| Mar 2021   | Refresh, makefile, more tests                        |
| Nov 2020   | New pipelines & code/ API robustness                 |
| Dec 2019   | Github Actions and AKS                               |
| Sept 2019  | New release pipelines and config moved to env vars   |
| Sept 2018  | Updated with weather API and weather view            |
| July 2018  | Updated Vue CLI config & moved to Golang 1.11        |
| April 2018 | Project created                                      |
