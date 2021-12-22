package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
)

var regex = regexp.MustCompile(`^(?P<Action>on|off) x=(?P<X1>-?\d+)\.\.(?P<X2>-?\d+),y=(?P<Y1>-?\d+)\.\.(?P<Y2>-?\d+),z=(?P<Z1>-?\d+)\.\.(?P<Z2>-?\d+)$`)

func min(a, b int64) int64 {
	if a < b {
		return a
	}
	return b
}

func max(a, b int64) int64 {
	if a > b {
		return a
	}
	return b
}

type Cuboid struct {
	X, Y, Z, LX, LY, LZ int64
	TurnOn              bool
}

func (this Cuboid) X_() int64 {
	return this.X + this.LX
}

func (this Cuboid) Y_() int64 {
	return this.Y + this.LY
}

func (this Cuboid) Z_() int64 {
	return this.Z + this.LZ
}

func (this Cuboid) Volume() int64 {
	return this.LX * this.LY * this.LZ
}

func (this Cuboid) Intersect(other Cuboid) *Cuboid {
	nx1, nx2 := max(this.X, other.X), min(this.X_(), other.X_())
	ny1, ny2 := max(this.Y, other.Y), min(this.Y_(), other.Y_())
	nz1, nz2 := max(this.Z, other.Z), min(this.Z_(), other.Z_())
	if nx1 >= nx2 || ny1 >= ny2 || nz1 >= nz2 {
		return nil
	}
	return &Cuboid{
		X:  nx1,
		Y:  ny1,
		Z:  nz1,
		LX: nx2 - nx1,
		LY: ny2 - ny1,
		LZ: nz2 - nz1,
	}
}

func (this Cuboid) Difference(other Cuboid) []Cuboid {
	inter := this.Intersect(other)
	if inter == nil {
		return []Cuboid{this}
	}
	var cuboids []Cuboid
	if this.X < inter.X {
		cuboids = append(cuboids, Cuboid{
			X:  this.X,
			Y:  this.Y,
			Z:  this.Z,
			LX: inter.X - this.X,
			LY: this.LY,
			LZ: this.LZ,
		})
	}
	if this.X_() > inter.X_() {
		cuboids = append(cuboids, Cuboid{
			X:  inter.X_(),
			Y:  this.Y,
			Z:  this.Z,
			LX: this.X_() - inter.X_(),
			LY: this.LY,
			LZ: this.LZ,
		})
	}
	if this.Y < inter.Y {
		cuboids = append(cuboids, Cuboid{
			X:  inter.X,
			Y:  this.Y,
			Z:  this.Z,
			LX: inter.LX,
			LY: inter.Y - this.Y,
			LZ: this.LZ,
		})
	}
	if this.Y_() > inter.Y_() {
		cuboids = append(cuboids, Cuboid{
			X:  inter.X,
			Y:  inter.Y_(),
			Z:  this.Z,
			LX: inter.LX,
			LY: this.Y_() - inter.Y_(),
			LZ: this.LZ,
		})
	}
	if this.Z < inter.Z {
		cuboids = append(cuboids, Cuboid{
			X:  inter.X,
			Y:  inter.Y,
			Z:  this.Z,
			LX: inter.LX,
			LY: inter.LY,
			LZ: inter.Z - this.Z,
		})
	}
	if this.Z_() > inter.Z_() {
		cuboids = append(cuboids, Cuboid{
			X:  inter.X,
			Y:  inter.Y,
			Z:  inter.Z_(),
			LX: inter.LX,
			LY: inter.LY,
			LZ: this.Z_() - inter.Z_(),
		})
	}
	return cuboids
}

func (this Cuboid) turnOn(cuboids []Cuboid) []Cuboid {
	turnedOnCuboids := []Cuboid{this}
	for _, cuboid := range cuboids {
		var newTurnedOnCuboids []Cuboid
		for _, turnedOnCuboid := range turnedOnCuboids {
			newTurnedOnCuboids = append(newTurnedOnCuboids, turnedOnCuboid.Difference(cuboid)...)
		}
		turnedOnCuboids = newTurnedOnCuboids
	}
	return append(cuboids, turnedOnCuboids...)
}

func (this Cuboid) turnOff(cuboids []Cuboid) []Cuboid {
	var turnedOnCuboids []Cuboid
	for _, cuboid := range cuboids {
		turnedOnCuboids = append(turnedOnCuboids, cuboid.Difference(this)...)
	}
	return turnedOnCuboids
}

func readInputCuboid(reader *bufio.Reader) *Cuboid {
	line, _, _ := reader.ReadLine()
	if line == nil {
		return nil
	}
	turnOn := regex.ReplaceAllString(string(line), "${Action}") == "on"
	x1, _ := strconv.Atoi(regex.ReplaceAllString(string(line), "${X1}"))
	y1, _ := strconv.Atoi(regex.ReplaceAllString(string(line), "${Y1}"))
	z1, _ := strconv.Atoi(regex.ReplaceAllString(string(line), "${Z1}"))
	x2, _ := strconv.Atoi(regex.ReplaceAllString(string(line), "${X2}"))
	y2, _ := strconv.Atoi(regex.ReplaceAllString(string(line), "${Y2}"))
	z2, _ := strconv.Atoi(regex.ReplaceAllString(string(line), "${Z2}"))
	return &Cuboid{
		TurnOn: turnOn,
		X:      int64(x1),
		Y:      int64(y1),
		Z:      int64(z1),
		LX:     int64(x2 - x1 + 1),
		LY:     int64(y2 - y1 + 1),
		LZ:     int64(z2 - z1 + 1),
	}
}

func filterInitializationCuboids(cuboids []Cuboid) []Cuboid {
	f := func(value int64) bool { return -50 <= value && value <= 51 }
	var initCuboids []Cuboid
	for _, cuboid := range cuboids {
		if f(cuboid.X) && f(cuboid.Y) && f(cuboid.Z) && f(cuboid.X_()) && f(cuboid.Y_()) && f(cuboid.Z_()) {
			initCuboids = append(initCuboids, cuboid)
		}
	}
	return initCuboids
}

func processCuboids(cuboids []Cuboid) []Cuboid {
	var newCuboids []Cuboid
	for _, cuboid := range cuboids {
		if cuboid.TurnOn {
			newCuboids = cuboid.turnOn(newCuboids)
		} else {
			newCuboids = cuboid.turnOff(newCuboids)
		}
	}
	return newCuboids
}

func computeVolume(cuboids []Cuboid) int64 {
	var volume int64
	for _, cuboid := range cuboids {
		volume += cuboid.Volume()
	}
	return volume
}

func main() {
	file, _ := os.Open("input.txt")
	reader := bufio.NewReader(file)
	var cuboids []Cuboid
	for {
		cuboid := readInputCuboid(reader)
		if cuboid == nil {
			break
		} else {
			cuboids = append(cuboids, *cuboid)
		}
	}
	fmt.Println("2021-12-22 Part 1:", computeVolume(processCuboids(filterInitializationCuboids(cuboids))))
	fmt.Println("2021-12-22 Part 2:", computeVolume(processCuboids(cuboids)))
}
