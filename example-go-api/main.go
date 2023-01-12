package main

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

// album represents data about a record album.
type album struct {
	ID     string  `json:"id"`
	Title  string  `json:"title"`
	Artist string  `json:"artist"`
	Price  float64 `json:"price"`
}
type msg struct {
	Msg   string `json:"msg"`
	Value string `json:"value"`
	From  string `json:"from cluster"`
}

// albums slice to seed record album data.
var albums = []album{
	{ID: "1", Title: "Blue Train", Artist: "John Coltrane", Price: 56.99},
	{ID: "2", Title: "Jeru", Artist: "Gerry Mulligan", Price: 17.99},
	{ID: "3", Title: "Sarah Vaughan and Clifford Brown", Artist: "Sarah Vaughan", Price: 39.99},
}

func getAlbums(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, albums)
}

func getrootRoute(c *gin.Context) {
	clusterColor := os.Getenv("cluster_color")
	msg := msg{Msg: "msg", Value: "hi this is root route", From: clusterColor}
	c.IndentedJSON(http.StatusOK, msg)
}

func main() {
	router := gin.Default()
	router.GET("/albums", getAlbums)
	router.GET("/", getrootRoute)
	router.Run("0.0.0.0:8080")
}
