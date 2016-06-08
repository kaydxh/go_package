package logger

import (
	"github.com/cihub/seelog"
)

var Logger seelog.LoggerInterface

func Init() {
	Logger, _ = seelog.LoggerFromConfigAsFile("seelog.xml")
}
