var ZWEventHandler ={
    
callNativeFunction:function(nativeMethodName,params,callBackID,callBack){
    var message;
    
    if(!callBack){
        
        message = {'methodName':nativeMethodName,'params':params};
        window.webkit.messageHandlers.ZWEventHandler.postMessage(message);
        
    }else{
        message = {'methodName':nativeMethodName,'params':params,'callBackID':callBackID};
        if(!ZWBridgeEvent._listeners[callBackID]){
        ZWBridgeEvent.addEvent(callBackID, function(data){
                       
                       callBack(data);
                       
                       });
        }
        window.webkit.messageHandlers.ZWEventHandler.postMessage(message);
    }
    
    
},

callBack:function(callBackID,data){
    
    ZWBridgeEvent.fireEvent(callBackID,data);
    
},

registerHandler:function(methodName,callBack){
    
    if(!ZWBridgeEvent._listeners[methodName]){

        ZWBridgeEvent.addEvent(methodName, function(data){
                              
                               callBack(data,function(params){

                                        message = {'methodName':methodName,'params':params};
                                        window.webkit.messageHandlers.ZWEventHandler.postMessage(message);

                                        });

                               });
    }

},
removeAllCallBacks:function(data){
    ZWBridgeEvent._listeners ={};
}


};



var ZWBridgeEvent = {
    
_listeners: {},
    
    
addEvent: function(type, fn) {
    if (typeof this._listeners[type] === "undefined") {
        this._listeners[type] = [];
    }
    if (typeof fn === "function") {
        this._listeners[type].push(fn);
    }
    
    return this;
},
    
    
fireEvent: function(type,param) {
    var arrayEvent = this._listeners[type];
    if (arrayEvent instanceof Array) {
        for (var i=0, length=arrayEvent.length; i<length; i+=1) {
            if (typeof arrayEvent[i] === "function") {
                arrayEvent[i](param);
            }
        }
    }
    
    return this;
},
    
removeEvent: function(type, fn) {
    var arrayEvent = this._listeners[type];
    if (typeof type === "string" && arrayEvent instanceof Array) {
        if (typeof fn === "function") {
            for (var i=0, length=arrayEvent.length; i<length; i+=1){
                if (arrayEvent[i] === fn){
                    this._listeners[type].splice(i, 1);
                    break;
                }
            }
        } else {
            delete this._listeners[type];
        }
    }
    
    return this;
}
};


