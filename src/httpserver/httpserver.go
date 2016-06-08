package main

import (
	"container/list"
	"logger"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"request"
	"response"
	"strconv"
	"sync"
	"time"
	"utils"
)

//var g_lock sync.Mutex
var g_rwlock sync.RWMutex

type HttpServer interface {
	StartService()
}

var ListTaskToDo *list.List
var ListTaskDone *list.List
var ListTaskFailed *list.List
var CurrentTask request.CreateRequest

type PackageServer struct {
	request_          request.RequestIf
	response_         response.ResponseIf
	svn_package_path_ string
}

var exec_path string

func (pkgs *PackageServer) StartService() {
	go pkgs.TaskProcess()
	err := http.ListenAndServe(":8080", pkgs)
	if err != nil {
		logger.Logger.Error("Start server failed:", err.Error())
	}
}

func Contain(tasklist *list.List, val interface{}) (*list.Element, bool) {
	//g_lock.Lock()
	//defer g_lock.Unlock()
	g_rwlock.Lock()
	defer g_rwlock.Unlock()

	for e := tasklist.Front(); e != nil; e = e.Next() {
		if e.Value == val {
			return e, true
		}
	}

	return nil, false
}

func (pkgs *PackageServer) CheckParam(r *http.Request) (request.CreateRequest, bool /*repeat*/, int, bool /*ok*/) {
	rsp, cr, ok := pkgs.request_.Resolve(r)
	if !ok {
		logger.Logger.Error("Request Resolve failed.")
		pkgs.response_ = rsp

		return cr, true, 0, false
	}

	if cr.RemotePath == "" {
		return cr, true, 0, false
	}

	if cr.Operator != utils.CANCEL_TASK {
		cr.Operator = utils.START_TASK
	}

	//default version is newest
	if cr.SvnVersion < 0 {
		cr.SvnVersion = 0
	}

	var preTaskCount int = 0

	logger.Logger.Info("Request SvnVersion ", cr.SvnVersion)
	if cr.ProjCode >= 0 {
		_, oktodo := Contain(ListTaskToDo, cr)
		_, okdone := Contain(ListTaskDone, cr)
		if !oktodo && !okdone && cr.Operator == utils.START_TASK {
			//g_lock.Lock()
			g_rwlock.Lock()
			ListTaskToDo.PushBack(cr)
			preTaskCount = ListTaskToDo.Len() - 1
			logger.Logger.Info("add task:  ", cr)
			//g_lock.Unlock()
			g_rwlock.Unlock()

			return cr, false, preTaskCount, true
		} else if cr.Operator == utils.START_TASK && cr.SvnVersion == 0 { //if SvnVersion==0，allways process it
			//g_lock.Lock()
			g_rwlock.Lock()
			ListTaskToDo.PushBack(cr)
			preTaskCount = ListTaskToDo.Len() - 1
			logger.Logger.Info("add task:  ", cr)
			//g_lock.Unlock()
			g_rwlock.Unlock()

			return cr, false, preTaskCount, true
		}

		return cr, true, preTaskCount, true
	}
	return cr, true, preTaskCount, false
}

func (pkgs *PackageServer) InterTaskProcess(cr request.CreateRequest) bool {
	logger.Logger.Info("InterTaskProcess ", cr)
	cmd := exec.Command(pkgs.svn_package_path_, strconv.Itoa(cr.ProjCode), strconv.Itoa(cr.SvnVersion),
		strconv.Itoa(cr.SvnDocVersion), strconv.Itoa(cr.SvnThriftVersion), cr.RemotePath, exec_path)
	//cmd := exec.Command(pkgs.svn_package_path_, strconv.Itoa(cr.ProjCode), strconv.Itoa(cr.SvnVersion), cr.RemotePath, exec_path)

	if err := cmd.Start(); err != nil {
		logger.Logger.Error("command Run failed:", err.Error())
		return false
	}

	CurrentTask = cr
	logger.Logger.Info("CurrentTask:", CurrentTask)

	if err := cmd.Wait(); err != nil {
		logger.Logger.Error("command Wait failed:", err.Error())
		return false
	}

	fi, err := os.Open(exec_path + `/result.txt`)
	if err != nil {
		logger.Logger.Info(CurrentTask, " task is failed.")
		return false
	}
	defer fi.Close()

	buf := make([]byte, 1, 1)
	fi.Read(buf)

	if buf[0] == '1' {
		logger.Logger.Info(CurrentTask, " task is finished.")
		g_rwlock.Lock()
		CurrentTask = request.CreateRequest{ProjCode: 0, SvnVersion: 0, Operator: 0}
		g_rwlock.Unlock()
		return true
	} else {
		logger.Logger.Info(CurrentTask, " task is failed.")
		g_rwlock.Lock()
		CurrentTask = request.CreateRequest{ProjCode: 0, SvnVersion: 0, Operator: 0}
		g_rwlock.Unlock()
		return false
	}
}

func (pkgs *PackageServer) TaskProcess() bool {
	logger.Logger.Info("--------TaskProcess----------")
	for {
		cr := ListTaskToDo.Front()
		if cr != nil {
			if ok := pkgs.InterTaskProcess(cr.Value.(request.CreateRequest)); ok { // do it
				g_rwlock.Lock()
				//g_lock.Lock()
				// for e := ListTaskToDo.Front(); e != nil; e = e.Next() {
				// 	logger.Logger.Info("--------TaskProcess---before-------ListTaskToDo ", e.Value.(request.CreateRequest))
				// }
				ListTaskToDo.Remove(cr)
				ListTaskDone.PushBack(cr.Value.(request.CreateRequest)) // delete the task from ListTaskDone
				g_rwlock.Unlock()
				//g_lock.Unlock()
			} else {
				g_rwlock.Lock()
				//g_lock.Lock()
				ListTaskToDo.Remove(cr)
				ListTaskFailed.PushBack(cr.Value.(request.CreateRequest))
				//g_lock.Unlock()
				g_rwlock.Unlock()
			}
		}

		time.Sleep(50 * time.Millisecond)
	}

	return true
}

func (pkgs *PackageServer) TaskCancel(cr request.CreateRequest) bool {
	cr.Operator = utils.START_TASK

	if e, oktodo := Contain(ListTaskToDo, cr); oktodo {
		//g_lock.Lock()
		g_rwlock.Lock()
		ListTaskToDo.Remove(e)
		g_rwlock.Unlock()
		//g_lock.Unlock()
	}

	if _, okdone := Contain(ListTaskDone, cr); okdone {
		return false
	}

	if CurrentTask == cr {
		cmd := exec.Command("killall", "-9", "svn_package.sh")
		if err := cmd.Run(); err != nil {
			logger.Logger.Error("command Run failed:", err.Error())
			return false
		}
	}

	return true
}

func (pkgs *PackageServer) ProcessGetMethod(w http.ResponseWriter, r *http.Request) {
	rsp, cr, ok := pkgs.request_.Resolve(r)
	if !ok {
		logger.Logger.Error("Request Resolve failed.")
	} else {
		if cr.SvnVersion <= 0 || cr.ProjCode < 0 {
			rsp = response.CreateResponse{Code: 406, What: "request param is error."}
			goto EXIT
		}
		_, oktodo := Contain(ListTaskToDo, cr)
		_, okdone := Contain(ListTaskDone, cr)
		_, okFailed := Contain(ListTaskFailed, cr)

		g_rwlock.Lock()
		defer g_rwlock.Unlock()

		if cr == CurrentTask {
			rsp = response.CreateResponse{Code: 200, What: "task is processing."}
			logger.Logger.Info("cr = ", cr, " task is processing.")
		} else if oktodo && !okdone {
			rsp = response.CreateResponse{Code: 201, What: "task is not start."}
			logger.Logger.Info("cr = ", cr, " task is not finish.")
		} else if !oktodo && okdone {
			rsp = response.CreateResponse{Code: 202, What: "task is finished."}
			logger.Logger.Info("cr = ", cr, " task is finish.")
		} else if okFailed {
			rsp = response.CreateResponse{Code: 204, What: "task is failed."}
			logger.Logger.Info("cr = ", cr, " task is failed.")
		} else if !oktodo && !okdone && !okFailed {
			rsp = response.CreateResponse{Code: 203, What: "task is new, not add the task."}
			logger.Logger.Info("cr = ", cr, " task is new, not add the task.")
		} else {
			logger.Logger.Info("cr = ", cr, " should not come here.")
		}
	}

EXIT:
	rp, ok := rsp.MakeResponseMsg()
	if !ok {
		logger.Logger.Error("Faild:", rp)
		return
	}
	w.Write(rp)
}

func (pkgs *PackageServer) ProcessPostMethod(w http.ResponseWriter, r *http.Request) {
	cr, repeat, preTaskCount, ok := pkgs.CheckParam(r)
	if !ok {
		w.Write([]byte("{\"code\":401, \"what\":\"request param is error..\"}"))
		logger.Logger.Error("CheckParam faild.")
		return
	} else {
		if cr.Operator == utils.CANCEL_TASK {
			if ok := pkgs.TaskCancel(cr); !ok {
				w.Write([]byte("{\"code\":403, \"what\":\"the task is finished.\"}"))
				logger.Logger.Error("TaskCancel faild, ", cr, " task is finished.")
				return
			} else {
				w.Write([]byte("{\"code\":205, \"what\":\"the task is cancel.\"}"))
				logger.Logger.Info("TaskCancel ok, ", cr, " task is cancel.")
				return
			}
		} else if repeat {
			w.Write([]byte("{\"code\":402, \"what\":\"the task is repeat.\"}"))
			logger.Logger.Info(cr, " task is repeat.")
			return
		} else {
			pkgs.response_ = response.CreateResponse{Code: 200, What: strconv.Itoa(preTaskCount) + " tasks before this task need process."}
			rsp, ok := pkgs.response_.MakeResponseMsg()
			if !ok {
				logger.Logger.Error("Faild:", rsp)
				return
			}
			w.Write(rsp)
		}
	}
}

func (pkgs PackageServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	logger.Logger.Info("-------------------------ServeHTTP------------------------")

	pkgs.request_ = &request.CreateRequest{}
	pkgs.response_ = response.CreateResponse{Code: 200, What: "task is processing.."}

	switch r.Method {
	case "GET":
		logger.Logger.Info("-------------------------GET------------------------")
		pkgs.ProcessGetMethod(w, r)
	case "POST":
		logger.Logger.Info("-------------------------POST-----------------------")
		pkgs.ProcessPostMethod(w, r)
	default:
		w.Write([]byte("{\"code\":400, \"what\":\"the method is not accepted.\"}"))
		logger.Logger.Error("{\"code\":400, \"what\":\"the method is not accepted.\"} ==>method:", r.Method)
	}
	return
}

func main() {

	logger.Init()
	ListTaskToDo = list.New()
	ListTaskDone = list.New()
	ListTaskFailed = list.New()

	file, _ := exec.LookPath(os.Args[0])
	path, _ := filepath.Abs(file)

	exec_path = utils.GetParentDirectory(path)
	svn_package_path := exec_path + "/svn_package.sh"

	var httpServer HttpServer
	httpServer = &PackageServer{svn_package_path_: svn_package_path}
	httpServer.StartService()
}
