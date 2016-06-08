代码编译：
1 先运行deps
2 再运行install
打包服务协议说明

一 客户端请求格式
1 请求编译
url=http://ip:8080/ 比如：http://192.168.0.231:/8080/
注意这里端口固定为8080
具体请求编译哪个工程，需使用post方法，具体内容以JOSN格式给出，
{
"projcode":xxx,
"svnversion":xxx,
"operator":xxx
"remotepath":"xxx"
}
如：
{
"projcode":1,
"svnversion":107050,
"operator":1
"remotepath":"/home/serverupdate/20160517_1.1.1/vrv"
}

字段说明：
1 project字段代表所要编译的工程代号，值为int型，必须大于等于0，目前支持3个工程的编译，分别为"projcode":0（apns project），"projcode":1（ap 
  project），"projcode":2（prelogin project）, "projcode":3（upload project）。

2 svnverion字段代表需要编译svn中哪个版本，值为int型，如，"svnversion":107050，即编译对应projcode工程中的107050版本，如果需要更新到svn最新的
  版本，该字段设置0即可,注意多次请求打包同个工程且svn号为0，服务器仍会执行该任务，而不会当做重复任务。

3 operator字段代表本次请求的操作内容，值为int型，0代表取消编译，1代表执行编译。如，client发送了{"projcode":1,"svnversion":107050,"operator":
  1}的post请求，但是随后发现svnvesrion版本号发送错了，想取消编译，可再次发送{"projcode":1,"svnversion":107050,"operator":0}，来取消该版本的编译。

4 remotepath字段代表上传到远端服务器（192.168.0.59）的根路径，如：/home/serverupdate/20160517_1.1.1/vrv

2 请求查询
请求查询使用Get方法：
http://ip:8080/?projcode=x&svnversion=x&remotepath=xxxxx
注意查询任务进度时：
a svnversion不能为0
b 取消任务进度不能查询，因为取消任务请求后，服务端直接返回了本次请求的结果。
二 服务器响应
    服务器返回给客户端的内容也是以json格式给出。格式为：
{
    "code":xxx,
    "what":xxxxxxxx
}

目前服务器同一时刻只能编译一个工程，所以如果对此有多个请求的话，需要排队逐个处理，如果请求的指令之前已经请求过，那么服务端会返回相关信息。
说明：
"code":200~300代表成功，其他为失败
//成功
200: task is processing 或 xxx tasks before this task need process。需要先处理队列中的xxx个任务后，才能处理本次请求任务,
     如果xxx为0，即表示正要处理本次请求任务。
201: task is not start.
202: task is finished.
203: task is new, not add the task.
204: task is failed.
205: the task is cancel。该任务取消成功。
//失败
400: the method is not accepted.。服务器不接受方法。
401: request param is error。client发送的请求指令有错误。
402: the task is repeat。本次请求的任务为重复任务，服务器已经处理过。
403: the task is finished。任务取消失败，该任务已经完成。



