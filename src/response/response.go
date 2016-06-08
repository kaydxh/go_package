package response

import (
	"encoding/json"
)

type ResponseInfo interface {
}

type ResponseIf interface {
	MakeResponseMsg() ([]byte, bool)
}

type CreateResponse struct {
	Code int    `json:"code"`
	What string `json:"what"`
}

func (rsp CreateResponse) MakeResponseMsg() ([]byte, bool) {
	outbyte, err := json.Marshal(rsp)
	if err != nil {
		return nil, false
	}

	return outbyte, true
}
