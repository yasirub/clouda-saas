FROM golang:1.17-alpine
WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./
RUN go get .
RUN go build -o /go-docker-demo

EXPOSE 8080

CMD [ "/go-docker-demo" ]