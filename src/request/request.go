package request

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"logger"
	"net/http"
	"response"
	"strconv"
)

type RequestInfo interface {
}

type RequestIf interface {
	Resolve(r RequestInfo) (response.ResponseIf, CreateRequest, bool)
}

type CreateRequest struct {
	ProjCode         int    `json:"projcode"`
	SvnVersion       int    `json:"svnversion"`
	SvnDocVersion    int    `json:"svndocversion"`
	SvnThriftVersion int    `json:"svnthriftversion"`
	Operator         int    `json:"operator"`
	RemotePath       string `json:remotepath`
}

func StringToInt(str string) (int, error) {
	if str == "" {
		return 0, errors.New("{code:-1}")
	}
	return strconv.Atoi(str)
}

func (cr *CreateRequest) Resolve(r RequestInfo) (response.ResponseIf, CreateRequest, bool) {
	req, ok := r.(*http.Request)
	if !ok {
		rsp := response.CreateResponse{Code: 1001, What: "Resolve error: invalid http request."}
		logger.Logger.Error("Resolve faild: invalid http request.")
		return rsp, *cr, false
	}

	if req.Method == "GET" {
		rsp := response.CreateResponse{Code: 1003, What: "Resolve error: invalid request data."}
		get_info := new(CreateRequest)
		value := req.URL.Query()

		ProjCode, err := StringToInt(value.Get("projcode"))
		if err != nil {
			logger.Logger.Error("Get ProjCode error")

			return rsp, *get_info, false
		}
		get_info.ProjCode = ProjCode

		SvnVersion, err := StringToInt(value.Get("svnversion"))
		if err != nil {
			logger.Logger.Error("Get SvnVersion error")
			return rsp, *get_info, false
		}
		get_info.SvnVersion = SvnVersion
		SvnDocVersion, _ := StringToInt(value.Get("svndocversion"))
		get_info.SvnDocVersion = SvnDocVersion

		SvnThriftVersion, _ := StringToInt(value.Get("svnthriftversion"))
		get_info.SvnThriftVersion = SvnThriftVersion

		get_info.RemotePath = value.Get("remotepath")
		get_info.Operator = 1
		logger.Logger.Info("get_info = ", get_info)

		return nil, *get_info, true

	} else if req.Method == "POST" {
		data_val, err := ioutil.ReadAll(req.Body)
		if err != nil {
		}

		if err := json.Unmarshal([]byte(data_val), &cr); err != nil {
			rsp := response.CreateResponse{Code: 1003, What: "Resolve error: invalid json data."}
			logger.Logger.Error("Resolve faild: invalid json data.")
			return rsp, *cr, false
		}
	}

	logger.Logger.Info("ProjCode ", cr.ProjCode, " SvnVersion ", cr.SvnVersion)
	logger.Logger.Info("Resolve finish.")

	return nil, *cr, true
}
