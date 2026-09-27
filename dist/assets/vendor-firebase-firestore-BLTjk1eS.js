const Jf=()=>{};var Wu={};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Vl=function(r){const t=[];let e=0;for(let n=0;n<r.length;n++){let s=r.charCodeAt(n);s<128?t[e++]=s:s<2048?(t[e++]=s>>6|192,t[e++]=s&63|128):(s&64512)===55296&&n+1<r.length&&(r.charCodeAt(n+1)&64512)===56320?(s=65536+((s&1023)<<10)+(r.charCodeAt(++n)&1023),t[e++]=s>>18|240,t[e++]=s>>12&63|128,t[e++]=s>>6&63|128,t[e++]=s&63|128):(t[e++]=s>>12|224,t[e++]=s>>6&63|128,t[e++]=s&63|128)}return t},Yf=function(r){const t=[];let e=0,n=0;for(;e<r.length;){const s=r[e++];if(s<128)t[n++]=String.fromCharCode(s);else if(s>191&&s<224){const i=r[e++];t[n++]=String.fromCharCode((s&31)<<6|i&63)}else if(s>239&&s<365){const i=r[e++],a=r[e++],u=r[e++],l=((s&7)<<18|(i&63)<<12|(a&63)<<6|u&63)-65536;t[n++]=String.fromCharCode(55296+(l>>10)),t[n++]=String.fromCharCode(56320+(l&1023))}else{const i=r[e++],a=r[e++];t[n++]=String.fromCharCode((s&15)<<12|(i&63)<<6|a&63)}}return t.join("")},Pl={byteToCharMap_:null,charToByteMap_:null,byteToCharMapWebSafe_:null,charToByteMapWebSafe_:null,ENCODED_VALS_BASE:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",get ENCODED_VALS(){return this.ENCODED_VALS_BASE+"+/="},get ENCODED_VALS_WEBSAFE(){return this.ENCODED_VALS_BASE+"-_."},HAS_NATIVE_SUPPORT:typeof atob=="function",encodeByteArray(r,t){if(!Array.isArray(r))throw Error("encodeByteArray takes an array as a parameter");this.init_();const e=t?this.byteToCharMapWebSafe_:this.byteToCharMap_,n=[];for(let s=0;s<r.length;s+=3){const i=r[s],a=s+1<r.length,u=a?r[s+1]:0,l=s+2<r.length,d=l?r[s+2]:0,f=i>>2,g=(i&3)<<4|u>>4;let E=(u&15)<<2|d>>6,V=d&63;l||(V=64,a||(E=64)),n.push(e[f],e[g],e[E],e[V])}return n.join("")},encodeString(r,t){return this.HAS_NATIVE_SUPPORT&&!t?btoa(r):this.encodeByteArray(Vl(r),t)},decodeString(r,t){return this.HAS_NATIVE_SUPPORT&&!t?atob(r):Yf(this.decodeStringToByteArray(r,t))},decodeStringToByteArray(r,t){this.init_();const e=t?this.charToByteMapWebSafe_:this.charToByteMap_,n=[];for(let s=0;s<r.length;){const i=e[r.charAt(s++)],u=s<r.length?e[r.charAt(s)]:0;++s;const d=s<r.length?e[r.charAt(s)]:64;++s;const g=s<r.length?e[r.charAt(s)]:64;if(++s,i==null||u==null||d==null||g==null)throw new Xf;const E=i<<2|u>>4;if(n.push(E),d!==64){const V=u<<4&240|d>>2;if(n.push(V),g!==64){const D=d<<6&192|g;n.push(D)}}}return n},init_(){if(!this.byteToCharMap_){this.byteToCharMap_={},this.charToByteMap_={},this.byteToCharMapWebSafe_={},this.charToByteMapWebSafe_={};for(let r=0;r<this.ENCODED_VALS.length;r++)this.byteToCharMap_[r]=this.ENCODED_VALS.charAt(r),this.charToByteMap_[this.byteToCharMap_[r]]=r,this.byteToCharMapWebSafe_[r]=this.ENCODED_VALS_WEBSAFE.charAt(r),this.charToByteMapWebSafe_[this.byteToCharMapWebSafe_[r]]=r,r>=this.ENCODED_VALS_BASE.length&&(this.charToByteMap_[this.ENCODED_VALS_WEBSAFE.charAt(r)]=r,this.charToByteMapWebSafe_[this.ENCODED_VALS.charAt(r)]=r)}}};class Xf extends Error{constructor(){super(...arguments),this.name="DecodeBase64StringError"}}const Zf=function(r){const t=Vl(r);return Pl.encodeByteArray(t,!0)},Cl=function(r){return Zf(r).replace(/\./g,"")},tm=function(r){try{return Pl.decodeString(r,!0)}catch(t){console.error("base64Decode failed: ",t)}return null};/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Dl(){if(typeof self<"u")return self;if(typeof window<"u")return window;if(typeof global<"u")return global;throw new Error("Unable to locate global object.")}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const em=()=>Dl().__FIREBASE_DEFAULTS__,nm=()=>{if(typeof process>"u"||typeof Wu>"u")return;const r=Wu.__FIREBASE_DEFAULTS__;if(r)return JSON.parse(r)},rm=()=>{if(typeof document>"u")return;let r;try{r=document.cookie.match(/__FIREBASE_DEFAULTS__=([^;]+)/)}catch{return}const t=r&&tm(r[1]);return t&&JSON.parse(t)},ci=()=>{try{return Jf()||em()||nm()||rm()}catch(r){console.info(`Unable to get __FIREBASE_DEFAULTS__ due to: ${r}`);return}},rI=r=>{var t,e;return(e=(t=ci())==null?void 0:t.emulatorHosts)==null?void 0:e[r]},xl=()=>{var r;return(r=ci())==null?void 0:r.config},sI=r=>{var t;return(t=ci())==null?void 0:t[`_${r}`]};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class sm{constructor(){this.reject=()=>{},this.resolve=()=>{},this.promise=new Promise((t,e)=>{this.resolve=t,this.reject=e})}wrapCallback(t){return(e,n)=>{e?this.reject(e):this.resolve(n),typeof t=="function"&&(this.promise.catch(()=>{}),t.length===1?t(e):t(e,n))}}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function wn(){return typeof navigator<"u"&&typeof navigator.userAgent=="string"?navigator.userAgent:""}function iI(){return typeof window<"u"&&!!(window.cordova||window.phonegap||window.PhoneGap)&&/ios|iphone|ipod|ipad|android|blackberry|iemobile/i.test(wn())}function Nl(){var t;const r=(t=ci())==null?void 0:t.forceEnvironment;if(r==="node")return!0;if(r==="browser")return!1;try{return Object.prototype.toString.call(global.process)==="[object process]"}catch{return!1}}function oI(){return typeof navigator<"u"&&navigator.userAgent==="Cloudflare-Workers"}function aI(){const r=typeof chrome=="object"?chrome.runtime:typeof browser=="object"?browser.runtime:void 0;return typeof r=="object"&&r.id!==void 0}function uI(){return typeof navigator=="object"&&navigator.product==="ReactNative"}function cI(){const r=wn();return r.indexOf("MSIE ")>=0||r.indexOf("Trident/")>=0}function kl(){return!Nl()&&!!navigator.userAgent&&navigator.userAgent.includes("Safari")&&!navigator.userAgent.includes("Chrome")}function Ml(){return!Nl()&&!!navigator.userAgent&&(navigator.userAgent.includes("Safari")||navigator.userAgent.includes("WebKit"))&&!navigator.userAgent.includes("Chrome")}function Ol(){try{return typeof indexedDB=="object"}catch{return!1}}function im(){return new Promise((r,t)=>{try{let e=!0;const n="validate-browser-context-for-indexeddb-analytics-module",s=self.indexedDB.open(n);s.onsuccess=()=>{s.result.close(),e||self.indexedDB.deleteDatabase(n),r(!0)},s.onupgradeneeded=()=>{e=!1},s.onerror=()=>{var i;t(((i=s.error)==null?void 0:i.message)||"")}}catch(e){t(e)}})}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const om="FirebaseError";class jn extends Error{constructor(t,e,n){super(e),this.code=t,this.customData=n,this.name=om,Object.setPrototypeOf(this,jn.prototype),Error.captureStackTrace&&Error.captureStackTrace(this,Fl.prototype.create)}}class Fl{constructor(t,e,n){this.service=t,this.serviceName=e,this.errors=n}create(t,...e){const n=e[0]||{},s=`${this.service}/${t}`,i=this.errors[t],a=i?am(i,n):"Error",u=`${this.serviceName}: ${a} (${s}).`;return new jn(s,u,n)}}function am(r,t){return r.replace(um,(e,n)=>{const s=t[n];return s!=null?String(s):`<${n}?>`})}const um=/\{\$([^}]+)}/g;function lI(r){for(const t in r)if(Object.prototype.hasOwnProperty.call(r,t))return!1;return!0}function Us(r,t){if(r===t)return!0;const e=Object.keys(r),n=Object.keys(t);for(const s of e){if(!n.includes(s))return!1;const i=r[s],a=t[s];if(Ju(i)&&Ju(a)){if(!Us(i,a))return!1}else if(i!==a)return!1}for(const s of n)if(!e.includes(s))return!1;return!0}function Ju(r){return r!==null&&typeof r=="object"}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function hI(r){const t=[];for(const[e,n]of Object.entries(r))Array.isArray(n)?n.forEach(s=>{t.push(encodeURIComponent(e)+"="+encodeURIComponent(s))}):t.push(encodeURIComponent(e)+"="+encodeURIComponent(n));return t.length?"&"+t.join("&"):""}function dI(r,t){const e=new cm(r,t);return e.subscribe.bind(e)}class cm{constructor(t,e){this.observers=[],this.unsubscribes=[],this.observerCount=0,this.task=Promise.resolve(),this.finalized=!1,this.onNoObservers=e,this.task.then(()=>{t(this)}).catch(n=>{this.error(n)})}next(t){this.forEachObserver(e=>{e.next(t)})}error(t){this.forEachObserver(e=>{e.error(t)}),this.close(t)}complete(){this.forEachObserver(t=>{t.complete()}),this.close()}subscribe(t,e,n){let s;if(t===void 0&&e===void 0&&n===void 0)throw new Error("Missing Observer.");lm(t,["next","error","complete"])?s=t:s={next:t,error:e,complete:n},s.next===void 0&&(s.next=ro),s.error===void 0&&(s.error=ro),s.complete===void 0&&(s.complete=ro);const i=this.unsubscribeOne.bind(this,this.observers.length);return this.finalized&&this.task.then(()=>{try{this.finalError?s.error(this.finalError):s.complete()}catch{}}),this.observers.push(s),i}unsubscribeOne(t){this.observers===void 0||this.observers[t]===void 0||(delete this.observers[t],this.observerCount-=1,this.observerCount===0&&this.onNoObservers!==void 0&&this.onNoObservers(this))}forEachObserver(t){if(!this.finalized)for(let e=0;e<this.observers.length;e++)this.sendOne(e,t)}sendOne(t,e){this.task.then(()=>{if(this.observers!==void 0&&this.observers[t]!==void 0)try{e(this.observers[t])}catch(n){typeof console<"u"&&console.error&&console.error(n)}})}close(t){this.finalized||(this.finalized=!0,t!==void 0&&(this.finalError=t),this.task.then(()=>{this.observers=void 0,this.onNoObservers=void 0}))}}function lm(r,t){if(typeof r!="object"||r===null)return!1;for(const e of t)if(e in r&&typeof r[e]=="function")return!0;return!1}function ro(){}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Ut(r){return r&&r._delegate?r._delegate:r}/**
 * @license
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Ll(r){try{return(r.startsWith("http://")||r.startsWith("https://")?new URL(r).hostname:r).endsWith(".cloudworkstations.dev")}catch{return!1}}async function hm(r){return(await fetch(r,{credentials:"include"})).ok}class xr{constructor(t,e,n){this.name=t,this.instanceFactory=e,this.type=n,this.multipleInstances=!1,this.serviceProps={},this.instantiationMode="LAZY",this.onInstanceCreated=null}setInstantiationMode(t){return this.instantiationMode=t,this}setMultipleInstances(t){return this.multipleInstances=t,this}setServiceProps(t){return this.serviceProps=t,this}setInstanceCreatedCallback(t){return this.onInstanceCreated=t,this}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Le="[DEFAULT]";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class dm{constructor(t,e){this.name=t,this.container=e,this.component=null,this.instances=new Map,this.instancesDeferred=new Map,this.instancesOptions=new Map,this.onInitCallbacks=new Map}get(t){const e=this.normalizeInstanceIdentifier(t);if(!this.instancesDeferred.has(e)){const n=new sm;if(this.instancesDeferred.set(e,n),this.isInitialized(e)||this.shouldAutoInitialize())try{const s=this.getOrInitializeService({instanceIdentifier:e});s&&n.resolve(s)}catch{}}return this.instancesDeferred.get(e).promise}getImmediate(t){const e=this.normalizeInstanceIdentifier(t==null?void 0:t.identifier),n=(t==null?void 0:t.optional)??!1;if(this.isInitialized(e)||this.shouldAutoInitialize())try{return this.getOrInitializeService({instanceIdentifier:e})}catch(s){if(n)return null;throw s}else{if(n)return null;throw Error(`Service ${this.name} is not available`)}}getComponent(){return this.component}setComponent(t){if(t.name!==this.name)throw Error(`Mismatching Component ${t.name} for Provider ${this.name}.`);if(this.component)throw Error(`Component for ${this.name} has already been provided`);if(this.component=t,!!this.shouldAutoInitialize()){if(mm(t))try{this.getOrInitializeService({instanceIdentifier:Le})}catch{}for(const[e,n]of this.instancesDeferred.entries()){const s=this.normalizeInstanceIdentifier(e);try{const i=this.getOrInitializeService({instanceIdentifier:s});n.resolve(i)}catch{}}}}clearInstance(t=Le){this.instancesDeferred.delete(t),this.instancesOptions.delete(t),this.instances.delete(t)}async delete(){const t=Array.from(this.instances.values());await Promise.all([...t.filter(e=>"INTERNAL"in e).map(e=>e.INTERNAL.delete()),...t.filter(e=>"_delete"in e).map(e=>e._delete())])}isComponentSet(){return this.component!=null}isInitialized(t=Le){return this.instances.has(t)}getOptions(t=Le){return this.instancesOptions.get(t)||{}}initialize(t={}){const{options:e={}}=t,n=this.normalizeInstanceIdentifier(t.instanceIdentifier);if(this.isInitialized(n))throw Error(`${this.name}(${n}) has already been initialized`);if(!this.isComponentSet())throw Error(`Component ${this.name} has not been registered yet`);const s=this.getOrInitializeService({instanceIdentifier:n,options:e});for(const[i,a]of this.instancesDeferred.entries()){const u=this.normalizeInstanceIdentifier(i);n===u&&a.resolve(s)}return s}onInit(t,e){const n=this.normalizeInstanceIdentifier(e),s=this.onInitCallbacks.get(n)??new Set;s.add(t),this.onInitCallbacks.set(n,s);const i=this.instances.get(n);return i&&t(i,n),()=>{s.delete(t)}}invokeOnInitCallbacks(t,e){const n=this.onInitCallbacks.get(e);if(n)for(const s of n)try{s(t,e)}catch{}}getOrInitializeService({instanceIdentifier:t,options:e={}}){let n=this.instances.get(t);if(!n&&this.component&&(n=this.component.instanceFactory(this.container,{instanceIdentifier:fm(t),options:e}),this.instances.set(t,n),this.instancesOptions.set(t,e),this.invokeOnInitCallbacks(n,t),this.component.onInstanceCreated))try{this.component.onInstanceCreated(this.container,t,n)}catch{}return n||null}normalizeInstanceIdentifier(t=Le){return this.component?this.component.multipleInstances?t:Le:t}shouldAutoInitialize(){return!!this.component&&this.component.instantiationMode!=="EXPLICIT"}}function fm(r){return r===Le?void 0:r}function mm(r){return r.instantiationMode==="EAGER"}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class gm{constructor(t){this.name=t,this.providers=new Map}addComponent(t){const e=this.getProvider(t.name);if(e.isComponentSet())throw new Error(`Component ${t.name} has already been registered with ${this.name}`);e.setComponent(t)}addOrOverwriteComponent(t){this.getProvider(t.name).isComponentSet()&&this.providers.delete(t.name),this.addComponent(t)}getProvider(t){if(this.providers.has(t))return this.providers.get(t);const e=new dm(t,this);return this.providers.set(t,e),e}getProviders(){return Array.from(this.providers.values())}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */var Q;(function(r){r[r.DEBUG=0]="DEBUG",r[r.VERBOSE=1]="VERBOSE",r[r.INFO=2]="INFO",r[r.WARN=3]="WARN",r[r.ERROR=4]="ERROR",r[r.SILENT=5]="SILENT"})(Q||(Q={}));const pm={debug:Q.DEBUG,verbose:Q.VERBOSE,info:Q.INFO,warn:Q.WARN,error:Q.ERROR,silent:Q.SILENT},_m=Q.INFO,ym={[Q.DEBUG]:"log",[Q.VERBOSE]:"log",[Q.INFO]:"info",[Q.WARN]:"warn",[Q.ERROR]:"error"},Im=(r,t,...e)=>{if(t<r.logLevel)return;const n=new Date().toISOString(),s=ym[t];if(s)console[s](`[${n}]  ${r.name}:`,...e);else throw new Error(`Attempted to log a message with an invalid logType (value: ${t})`)};class Bl{constructor(t){this.name=t,this._logLevel=_m,this._logHandler=Im,this._userLogHandler=null}get logLevel(){return this._logLevel}set logLevel(t){if(!(t in Q))throw new TypeError(`Invalid value "${t}" assigned to \`logLevel\``);this._logLevel=t}setLogLevel(t){this._logLevel=typeof t=="string"?pm[t]:t}get logHandler(){return this._logHandler}set logHandler(t){if(typeof t!="function")throw new TypeError("Value assigned to `logHandler` must be a function");this._logHandler=t}get userLogHandler(){return this._userLogHandler}set userLogHandler(t){this._userLogHandler=t}debug(...t){this._userLogHandler&&this._userLogHandler(this,Q.DEBUG,...t),this._logHandler(this,Q.DEBUG,...t)}log(...t){this._userLogHandler&&this._userLogHandler(this,Q.VERBOSE,...t),this._logHandler(this,Q.VERBOSE,...t)}info(...t){this._userLogHandler&&this._userLogHandler(this,Q.INFO,...t),this._logHandler(this,Q.INFO,...t)}warn(...t){this._userLogHandler&&this._userLogHandler(this,Q.WARN,...t),this._logHandler(this,Q.WARN,...t)}error(...t){this._userLogHandler&&this._userLogHandler(this,Q.ERROR,...t),this._logHandler(this,Q.ERROR,...t)}}const Em=(r,t)=>t.some(e=>r instanceof e);let Yu,Xu;function Tm(){return Yu||(Yu=[IDBDatabase,IDBObjectStore,IDBIndex,IDBCursor,IDBTransaction])}function wm(){return Xu||(Xu=[IDBCursor.prototype.advance,IDBCursor.prototype.continue,IDBCursor.prototype.continuePrimaryKey])}const Ul=new WeakMap,Io=new WeakMap,ql=new WeakMap,so=new WeakMap,Jo=new WeakMap;function vm(r){const t=new Promise((e,n)=>{const s=()=>{r.removeEventListener("success",i),r.removeEventListener("error",a)},i=()=>{e(_e(r.result)),s()},a=()=>{n(r.error),s()};r.addEventListener("success",i),r.addEventListener("error",a)});return t.then(e=>{e instanceof IDBCursor&&Ul.set(e,r)}).catch(()=>{}),Jo.set(t,r),t}function Am(r){if(Io.has(r))return;const t=new Promise((e,n)=>{const s=()=>{r.removeEventListener("complete",i),r.removeEventListener("error",a),r.removeEventListener("abort",a)},i=()=>{e(),s()},a=()=>{n(r.error||new DOMException("AbortError","AbortError")),s()};r.addEventListener("complete",i),r.addEventListener("error",a),r.addEventListener("abort",a)});Io.set(r,t)}let Eo={get(r,t,e){if(r instanceof IDBTransaction){if(t==="done")return Io.get(r);if(t==="objectStoreNames")return r.objectStoreNames||ql.get(r);if(t==="store")return e.objectStoreNames[1]?void 0:e.objectStore(e.objectStoreNames[0])}return _e(r[t])},set(r,t,e){return r[t]=e,!0},has(r,t){return r instanceof IDBTransaction&&(t==="done"||t==="store")?!0:t in r}};function bm(r){Eo=r(Eo)}function Rm(r){return r===IDBDatabase.prototype.transaction&&!("objectStoreNames"in IDBTransaction.prototype)?function(t,...e){const n=r.call(io(this),t,...e);return ql.set(n,t.sort?t.sort():[t]),_e(n)}:wm().includes(r)?function(...t){return r.apply(io(this),t),_e(Ul.get(this))}:function(...t){return _e(r.apply(io(this),t))}}function Sm(r){return typeof r=="function"?Rm(r):(r instanceof IDBTransaction&&Am(r),Em(r,Tm())?new Proxy(r,Eo):r)}function _e(r){if(r instanceof IDBRequest)return vm(r);if(so.has(r))return so.get(r);const t=Sm(r);return t!==r&&(so.set(r,t),Jo.set(t,r)),t}const io=r=>Jo.get(r);function Vm(r,t,{blocked:e,upgrade:n,blocking:s,terminated:i}={}){const a=indexedDB.open(r,t),u=_e(a);return n&&a.addEventListener("upgradeneeded",l=>{n(_e(a.result),l.oldVersion,l.newVersion,_e(a.transaction),l)}),e&&a.addEventListener("blocked",l=>e(l.oldVersion,l.newVersion,l)),u.then(l=>{i&&l.addEventListener("close",()=>i()),s&&l.addEventListener("versionchange",d=>s(d.oldVersion,d.newVersion,d))}).catch(()=>{}),u}const Pm=["get","getKey","getAll","getAllKeys","count"],Cm=["put","add","delete","clear"],oo=new Map;function Zu(r,t){if(!(r instanceof IDBDatabase&&!(t in r)&&typeof t=="string"))return;if(oo.get(t))return oo.get(t);const e=t.replace(/FromIndex$/,""),n=t!==e,s=Cm.includes(e);if(!(e in(n?IDBIndex:IDBObjectStore).prototype)||!(s||Pm.includes(e)))return;const i=async function(a,...u){const l=this.transaction(a,s?"readwrite":"readonly");let d=l.store;return n&&(d=d.index(u.shift())),(await Promise.all([d[e](...u),s&&l.done]))[0]};return oo.set(t,i),i}bm(r=>({...r,get:(t,e,n)=>Zu(t,e)||r.get(t,e,n),has:(t,e)=>!!Zu(t,e)||r.has(t,e)}));/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Dm{constructor(t){this.container=t}getPlatformInfoString(){return this.container.getProviders().map(e=>{if(xm(e)){const n=e.getImmediate();return`${n.library}/${n.version}`}else return null}).filter(e=>e).join(" ")}}function xm(r){const t=r.getComponent();return(t==null?void 0:t.type)==="VERSION"}const To="@firebase/app",tc="0.14.10";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const ee=new Bl("@firebase/app"),Nm="@firebase/app-compat",km="@firebase/analytics-compat",Mm="@firebase/analytics",Om="@firebase/app-check-compat",Fm="@firebase/app-check",Lm="@firebase/auth",Bm="@firebase/auth-compat",Um="@firebase/database",qm="@firebase/data-connect",jm="@firebase/database-compat",zm="@firebase/functions",$m="@firebase/functions-compat",Gm="@firebase/installations",Km="@firebase/installations-compat",Hm="@firebase/messaging",Qm="@firebase/messaging-compat",Wm="@firebase/performance",Jm="@firebase/performance-compat",Ym="@firebase/remote-config",Xm="@firebase/remote-config-compat",Zm="@firebase/storage",tg="@firebase/storage-compat",eg="@firebase/firestore",ng="@firebase/ai",rg="@firebase/firestore-compat",sg="firebase",ig="12.11.0";/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const wo="[DEFAULT]",og={[To]:"fire-core",[Nm]:"fire-core-compat",[Mm]:"fire-analytics",[km]:"fire-analytics-compat",[Fm]:"fire-app-check",[Om]:"fire-app-check-compat",[Lm]:"fire-auth",[Bm]:"fire-auth-compat",[Um]:"fire-rtdb",[qm]:"fire-data-connect",[jm]:"fire-rtdb-compat",[zm]:"fire-fn",[$m]:"fire-fn-compat",[Gm]:"fire-iid",[Km]:"fire-iid-compat",[Hm]:"fire-fcm",[Qm]:"fire-fcm-compat",[Wm]:"fire-perf",[Jm]:"fire-perf-compat",[Ym]:"fire-rc",[Xm]:"fire-rc-compat",[Zm]:"fire-gcs",[tg]:"fire-gcs-compat",[eg]:"fire-fst",[rg]:"fire-fst-compat",[ng]:"fire-vertex","fire-js":"fire-js",[sg]:"fire-js-all"};/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const qs=new Map,ag=new Map,vo=new Map;function ec(r,t){try{r.container.addComponent(t)}catch(e){ee.debug(`Component ${t.name} failed to register with FirebaseApp ${r.name}`,e)}}function js(r){const t=r.name;if(vo.has(t))return ee.debug(`There were multiple attempts to register component ${t}.`),!1;vo.set(t,r);for(const e of qs.values())ec(e,r);for(const e of ag.values())ec(e,r);return!0}function ug(r,t){const e=r.container.getProvider("heartbeat").getImmediate({optional:!0});return e&&e.triggerHeartbeat(),r.container.getProvider(t)}function cg(r){return r==null?!1:r.settings!==void 0}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const lg={"no-app":"No Firebase App '{$appName}' has been created - call initializeApp() first","bad-app-name":"Illegal App name: '{$appName}'","duplicate-app":"Firebase App named '{$appName}' already exists with different options or config","app-deleted":"Firebase App named '{$appName}' already deleted","server-app-deleted":"Firebase Server App has been deleted","no-options":"Need to provide options, when not being deployed to hosting via source.","invalid-app-argument":"firebase.{$appName}() takes either no argument or a Firebase App instance.","invalid-log-argument":"First argument to `onLog` must be null or a function.","idb-open":"Error thrown when opening IndexedDB. Original error: {$originalErrorMessage}.","idb-get":"Error thrown when reading from IndexedDB. Original error: {$originalErrorMessage}.","idb-set":"Error thrown when writing to IndexedDB. Original error: {$originalErrorMessage}.","idb-delete":"Error thrown when deleting from IndexedDB. Original error: {$originalErrorMessage}.","finalization-registry-not-supported":"FirebaseServerApp deleteOnDeref field defined but the JS runtime does not support FinalizationRegistry.","invalid-server-app-environment":"FirebaseServerApp is not for use in browser environments."},ye=new Fl("app","Firebase",lg);/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class hg{constructor(t,e,n){this._isDeleted=!1,this._options={...t},this._config={...e},this._name=e.name,this._automaticDataCollectionEnabled=e.automaticDataCollectionEnabled,this._container=n,this.container.addComponent(new xr("app",()=>this,"PUBLIC"))}get automaticDataCollectionEnabled(){return this.checkDestroyed(),this._automaticDataCollectionEnabled}set automaticDataCollectionEnabled(t){this.checkDestroyed(),this._automaticDataCollectionEnabled=t}get name(){return this.checkDestroyed(),this._name}get options(){return this.checkDestroyed(),this._options}get config(){return this.checkDestroyed(),this._config}get container(){return this._container}get isDeleted(){return this._isDeleted}set isDeleted(t){this._isDeleted=t}checkDestroyed(){if(this.isDeleted)throw ye.create("app-deleted",{appName:this._name})}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const dg=ig;function fg(r,t={}){let e=r;typeof t!="object"&&(t={name:t});const n={name:wo,automaticDataCollectionEnabled:!0,...t},s=n.name;if(typeof s!="string"||!s)throw ye.create("bad-app-name",{appName:String(s)});if(e||(e=xl()),!e)throw ye.create("no-options");const i=qs.get(s);if(i){if(Us(e,i.options)&&Us(n,i.config))return i;throw ye.create("duplicate-app",{appName:s})}const a=new gm(s);for(const l of vo.values())a.addComponent(l);const u=new hg(e,n,a);return qs.set(s,u),u}function fI(r=wo){const t=qs.get(r);if(!t&&r===wo&&xl())return fg();if(!t)throw ye.create("no-app",{appName:r});return t}function wr(r,t,e){let n=og[r]??r;e&&(n+=`-${e}`);const s=n.match(/\s|\//),i=t.match(/\s|\//);if(s||i){const a=[`Unable to register library "${n}" with version "${t}":`];s&&a.push(`library name "${n}" contains illegal characters (whitespace or "/")`),s&&i&&a.push("and"),i&&a.push(`version name "${t}" contains illegal characters (whitespace or "/")`),ee.warn(a.join(" "));return}js(new xr(`${n}-version`,()=>({library:n,version:t}),"VERSION"))}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const mg="firebase-heartbeat-database",gg=1,Nr="firebase-heartbeat-store";let ao=null;function jl(){return ao||(ao=Vm(mg,gg,{upgrade:(r,t)=>{switch(t){case 0:try{r.createObjectStore(Nr)}catch(e){console.warn(e)}}}}).catch(r=>{throw ye.create("idb-open",{originalErrorMessage:r.message})})),ao}async function pg(r){try{const e=(await jl()).transaction(Nr),n=await e.objectStore(Nr).get(zl(r));return await e.done,n}catch(t){if(t instanceof jn)ee.warn(t.message);else{const e=ye.create("idb-get",{originalErrorMessage:t==null?void 0:t.message});ee.warn(e.message)}}}async function nc(r,t){try{const n=(await jl()).transaction(Nr,"readwrite");await n.objectStore(Nr).put(t,zl(r)),await n.done}catch(e){if(e instanceof jn)ee.warn(e.message);else{const n=ye.create("idb-set",{originalErrorMessage:e==null?void 0:e.message});ee.warn(n.message)}}}function zl(r){return`${r.name}!${r.options.appId}`}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const _g=1024,yg=30;class Ig{constructor(t){this.container=t,this._heartbeatsCache=null;const e=this.container.getProvider("app").getImmediate();this._storage=new Tg(e),this._heartbeatsCachePromise=this._storage.read().then(n=>(this._heartbeatsCache=n,n))}async triggerHeartbeat(){var t,e;try{const s=this.container.getProvider("platform-logger").getImmediate().getPlatformInfoString(),i=rc();if(((t=this._heartbeatsCache)==null?void 0:t.heartbeats)==null&&(this._heartbeatsCache=await this._heartbeatsCachePromise,((e=this._heartbeatsCache)==null?void 0:e.heartbeats)==null)||this._heartbeatsCache.lastSentHeartbeatDate===i||this._heartbeatsCache.heartbeats.some(a=>a.date===i))return;if(this._heartbeatsCache.heartbeats.push({date:i,agent:s}),this._heartbeatsCache.heartbeats.length>yg){const a=wg(this._heartbeatsCache.heartbeats);this._heartbeatsCache.heartbeats.splice(a,1)}return this._storage.overwrite(this._heartbeatsCache)}catch(n){ee.warn(n)}}async getHeartbeatsHeader(){var t;try{if(this._heartbeatsCache===null&&await this._heartbeatsCachePromise,((t=this._heartbeatsCache)==null?void 0:t.heartbeats)==null||this._heartbeatsCache.heartbeats.length===0)return"";const e=rc(),{heartbeatsToSend:n,unsentEntries:s}=Eg(this._heartbeatsCache.heartbeats),i=Cl(JSON.stringify({version:2,heartbeats:n}));return this._heartbeatsCache.lastSentHeartbeatDate=e,s.length>0?(this._heartbeatsCache.heartbeats=s,await this._storage.overwrite(this._heartbeatsCache)):(this._heartbeatsCache.heartbeats=[],this._storage.overwrite(this._heartbeatsCache)),i}catch(e){return ee.warn(e),""}}}function rc(){return new Date().toISOString().substring(0,10)}function Eg(r,t=_g){const e=[];let n=r.slice();for(const s of r){const i=e.find(a=>a.agent===s.agent);if(i){if(i.dates.push(s.date),sc(e)>t){i.dates.pop();break}}else if(e.push({agent:s.agent,dates:[s.date]}),sc(e)>t){e.pop();break}n=n.slice(1)}return{heartbeatsToSend:e,unsentEntries:n}}class Tg{constructor(t){this.app=t,this._canUseIndexedDBPromise=this.runIndexedDBEnvironmentCheck()}async runIndexedDBEnvironmentCheck(){return Ol()?im().then(()=>!0).catch(()=>!1):!1}async read(){if(await this._canUseIndexedDBPromise){const e=await pg(this.app);return e!=null&&e.heartbeats?e:{heartbeats:[]}}else return{heartbeats:[]}}async overwrite(t){if(await this._canUseIndexedDBPromise){const n=await this.read();return nc(this.app,{lastSentHeartbeatDate:t.lastSentHeartbeatDate??n.lastSentHeartbeatDate,heartbeats:t.heartbeats})}else return}async add(t){if(await this._canUseIndexedDBPromise){const n=await this.read();return nc(this.app,{lastSentHeartbeatDate:t.lastSentHeartbeatDate??n.lastSentHeartbeatDate,heartbeats:[...n.heartbeats,...t.heartbeats]})}else return}}function sc(r){return Cl(JSON.stringify({version:2,heartbeats:r})).length}function wg(r){if(r.length===0)return-1;let t=0,e=r[0].date;for(let n=1;n<r.length;n++)r[n].date<e&&(e=r[n].date,t=n);return t}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function vg(r){js(new xr("platform-logger",t=>new Dm(t),"PRIVATE")),js(new xr("heartbeat",t=>new Ig(t),"PRIVATE")),wr(To,tc,r),wr(To,tc,"esm2020"),wr("fire-js","")}vg("");var ic=typeof globalThis<"u"?globalThis:typeof window<"u"?window:typeof global<"u"?global:typeof self<"u"?self:{};/** @license
Copyright The Closure Library Authors.
SPDX-License-Identifier: Apache-2.0
*/var Ie,$l;(function(){var r;/** @license

 Copyright The Closure Library Authors.
 SPDX-License-Identifier: Apache-2.0
*/function t(I,p){function y(){}y.prototype=p.prototype,I.F=p.prototype,I.prototype=new y,I.prototype.constructor=I,I.D=function(w,T,b){for(var _=Array(arguments.length-2),Ct=2;Ct<arguments.length;Ct++)_[Ct-2]=arguments[Ct];return p.prototype[T].apply(w,_)}}function e(){this.blockSize=-1}function n(){this.blockSize=-1,this.blockSize=64,this.g=Array(4),this.C=Array(this.blockSize),this.o=this.h=0,this.u()}t(n,e),n.prototype.u=function(){this.g[0]=1732584193,this.g[1]=4023233417,this.g[2]=2562383102,this.g[3]=271733878,this.o=this.h=0};function s(I,p,y){y||(y=0);const w=Array(16);if(typeof p=="string")for(var T=0;T<16;++T)w[T]=p.charCodeAt(y++)|p.charCodeAt(y++)<<8|p.charCodeAt(y++)<<16|p.charCodeAt(y++)<<24;else for(T=0;T<16;++T)w[T]=p[y++]|p[y++]<<8|p[y++]<<16|p[y++]<<24;p=I.g[0],y=I.g[1],T=I.g[2];let b=I.g[3],_;_=p+(b^y&(T^b))+w[0]+3614090360&4294967295,p=y+(_<<7&4294967295|_>>>25),_=b+(T^p&(y^T))+w[1]+3905402710&4294967295,b=p+(_<<12&4294967295|_>>>20),_=T+(y^b&(p^y))+w[2]+606105819&4294967295,T=b+(_<<17&4294967295|_>>>15),_=y+(p^T&(b^p))+w[3]+3250441966&4294967295,y=T+(_<<22&4294967295|_>>>10),_=p+(b^y&(T^b))+w[4]+4118548399&4294967295,p=y+(_<<7&4294967295|_>>>25),_=b+(T^p&(y^T))+w[5]+1200080426&4294967295,b=p+(_<<12&4294967295|_>>>20),_=T+(y^b&(p^y))+w[6]+2821735955&4294967295,T=b+(_<<17&4294967295|_>>>15),_=y+(p^T&(b^p))+w[7]+4249261313&4294967295,y=T+(_<<22&4294967295|_>>>10),_=p+(b^y&(T^b))+w[8]+1770035416&4294967295,p=y+(_<<7&4294967295|_>>>25),_=b+(T^p&(y^T))+w[9]+2336552879&4294967295,b=p+(_<<12&4294967295|_>>>20),_=T+(y^b&(p^y))+w[10]+4294925233&4294967295,T=b+(_<<17&4294967295|_>>>15),_=y+(p^T&(b^p))+w[11]+2304563134&4294967295,y=T+(_<<22&4294967295|_>>>10),_=p+(b^y&(T^b))+w[12]+1804603682&4294967295,p=y+(_<<7&4294967295|_>>>25),_=b+(T^p&(y^T))+w[13]+4254626195&4294967295,b=p+(_<<12&4294967295|_>>>20),_=T+(y^b&(p^y))+w[14]+2792965006&4294967295,T=b+(_<<17&4294967295|_>>>15),_=y+(p^T&(b^p))+w[15]+1236535329&4294967295,y=T+(_<<22&4294967295|_>>>10),_=p+(T^b&(y^T))+w[1]+4129170786&4294967295,p=y+(_<<5&4294967295|_>>>27),_=b+(y^T&(p^y))+w[6]+3225465664&4294967295,b=p+(_<<9&4294967295|_>>>23),_=T+(p^y&(b^p))+w[11]+643717713&4294967295,T=b+(_<<14&4294967295|_>>>18),_=y+(b^p&(T^b))+w[0]+3921069994&4294967295,y=T+(_<<20&4294967295|_>>>12),_=p+(T^b&(y^T))+w[5]+3593408605&4294967295,p=y+(_<<5&4294967295|_>>>27),_=b+(y^T&(p^y))+w[10]+38016083&4294967295,b=p+(_<<9&4294967295|_>>>23),_=T+(p^y&(b^p))+w[15]+3634488961&4294967295,T=b+(_<<14&4294967295|_>>>18),_=y+(b^p&(T^b))+w[4]+3889429448&4294967295,y=T+(_<<20&4294967295|_>>>12),_=p+(T^b&(y^T))+w[9]+568446438&4294967295,p=y+(_<<5&4294967295|_>>>27),_=b+(y^T&(p^y))+w[14]+3275163606&4294967295,b=p+(_<<9&4294967295|_>>>23),_=T+(p^y&(b^p))+w[3]+4107603335&4294967295,T=b+(_<<14&4294967295|_>>>18),_=y+(b^p&(T^b))+w[8]+1163531501&4294967295,y=T+(_<<20&4294967295|_>>>12),_=p+(T^b&(y^T))+w[13]+2850285829&4294967295,p=y+(_<<5&4294967295|_>>>27),_=b+(y^T&(p^y))+w[2]+4243563512&4294967295,b=p+(_<<9&4294967295|_>>>23),_=T+(p^y&(b^p))+w[7]+1735328473&4294967295,T=b+(_<<14&4294967295|_>>>18),_=y+(b^p&(T^b))+w[12]+2368359562&4294967295,y=T+(_<<20&4294967295|_>>>12),_=p+(y^T^b)+w[5]+4294588738&4294967295,p=y+(_<<4&4294967295|_>>>28),_=b+(p^y^T)+w[8]+2272392833&4294967295,b=p+(_<<11&4294967295|_>>>21),_=T+(b^p^y)+w[11]+1839030562&4294967295,T=b+(_<<16&4294967295|_>>>16),_=y+(T^b^p)+w[14]+4259657740&4294967295,y=T+(_<<23&4294967295|_>>>9),_=p+(y^T^b)+w[1]+2763975236&4294967295,p=y+(_<<4&4294967295|_>>>28),_=b+(p^y^T)+w[4]+1272893353&4294967295,b=p+(_<<11&4294967295|_>>>21),_=T+(b^p^y)+w[7]+4139469664&4294967295,T=b+(_<<16&4294967295|_>>>16),_=y+(T^b^p)+w[10]+3200236656&4294967295,y=T+(_<<23&4294967295|_>>>9),_=p+(y^T^b)+w[13]+681279174&4294967295,p=y+(_<<4&4294967295|_>>>28),_=b+(p^y^T)+w[0]+3936430074&4294967295,b=p+(_<<11&4294967295|_>>>21),_=T+(b^p^y)+w[3]+3572445317&4294967295,T=b+(_<<16&4294967295|_>>>16),_=y+(T^b^p)+w[6]+76029189&4294967295,y=T+(_<<23&4294967295|_>>>9),_=p+(y^T^b)+w[9]+3654602809&4294967295,p=y+(_<<4&4294967295|_>>>28),_=b+(p^y^T)+w[12]+3873151461&4294967295,b=p+(_<<11&4294967295|_>>>21),_=T+(b^p^y)+w[15]+530742520&4294967295,T=b+(_<<16&4294967295|_>>>16),_=y+(T^b^p)+w[2]+3299628645&4294967295,y=T+(_<<23&4294967295|_>>>9),_=p+(T^(y|~b))+w[0]+4096336452&4294967295,p=y+(_<<6&4294967295|_>>>26),_=b+(y^(p|~T))+w[7]+1126891415&4294967295,b=p+(_<<10&4294967295|_>>>22),_=T+(p^(b|~y))+w[14]+2878612391&4294967295,T=b+(_<<15&4294967295|_>>>17),_=y+(b^(T|~p))+w[5]+4237533241&4294967295,y=T+(_<<21&4294967295|_>>>11),_=p+(T^(y|~b))+w[12]+1700485571&4294967295,p=y+(_<<6&4294967295|_>>>26),_=b+(y^(p|~T))+w[3]+2399980690&4294967295,b=p+(_<<10&4294967295|_>>>22),_=T+(p^(b|~y))+w[10]+4293915773&4294967295,T=b+(_<<15&4294967295|_>>>17),_=y+(b^(T|~p))+w[1]+2240044497&4294967295,y=T+(_<<21&4294967295|_>>>11),_=p+(T^(y|~b))+w[8]+1873313359&4294967295,p=y+(_<<6&4294967295|_>>>26),_=b+(y^(p|~T))+w[15]+4264355552&4294967295,b=p+(_<<10&4294967295|_>>>22),_=T+(p^(b|~y))+w[6]+2734768916&4294967295,T=b+(_<<15&4294967295|_>>>17),_=y+(b^(T|~p))+w[13]+1309151649&4294967295,y=T+(_<<21&4294967295|_>>>11),_=p+(T^(y|~b))+w[4]+4149444226&4294967295,p=y+(_<<6&4294967295|_>>>26),_=b+(y^(p|~T))+w[11]+3174756917&4294967295,b=p+(_<<10&4294967295|_>>>22),_=T+(p^(b|~y))+w[2]+718787259&4294967295,T=b+(_<<15&4294967295|_>>>17),_=y+(b^(T|~p))+w[9]+3951481745&4294967295,I.g[0]=I.g[0]+p&4294967295,I.g[1]=I.g[1]+(T+(_<<21&4294967295|_>>>11))&4294967295,I.g[2]=I.g[2]+T&4294967295,I.g[3]=I.g[3]+b&4294967295}n.prototype.v=function(I,p){p===void 0&&(p=I.length);const y=p-this.blockSize,w=this.C;let T=this.h,b=0;for(;b<p;){if(T==0)for(;b<=y;)s(this,I,b),b+=this.blockSize;if(typeof I=="string"){for(;b<p;)if(w[T++]=I.charCodeAt(b++),T==this.blockSize){s(this,w),T=0;break}}else for(;b<p;)if(w[T++]=I[b++],T==this.blockSize){s(this,w),T=0;break}}this.h=T,this.o+=p},n.prototype.A=function(){var I=Array((this.h<56?this.blockSize:this.blockSize*2)-this.h);I[0]=128;for(var p=1;p<I.length-8;++p)I[p]=0;p=this.o*8;for(var y=I.length-8;y<I.length;++y)I[y]=p&255,p/=256;for(this.v(I),I=Array(16),p=0,y=0;y<4;++y)for(let w=0;w<32;w+=8)I[p++]=this.g[y]>>>w&255;return I};function i(I,p){var y=u;return Object.prototype.hasOwnProperty.call(y,I)?y[I]:y[I]=p(I)}function a(I,p){this.h=p;const y=[];let w=!0;for(let T=I.length-1;T>=0;T--){const b=I[T]|0;w&&b==p||(y[T]=b,w=!1)}this.g=y}var u={};function l(I){return-128<=I&&I<128?i(I,function(p){return new a([p|0],p<0?-1:0)}):new a([I|0],I<0?-1:0)}function d(I){if(isNaN(I)||!isFinite(I))return g;if(I<0)return M(d(-I));const p=[];let y=1;for(let w=0;I>=y;w++)p[w]=I/y|0,y*=4294967296;return new a(p,0)}function f(I,p){if(I.length==0)throw Error("number format error: empty string");if(p=p||10,p<2||36<p)throw Error("radix out of range: "+p);if(I.charAt(0)=="-")return M(f(I.substring(1),p));if(I.indexOf("-")>=0)throw Error('number format error: interior "-" character');const y=d(Math.pow(p,8));let w=g;for(let b=0;b<I.length;b+=8){var T=Math.min(8,I.length-b);const _=parseInt(I.substring(b,b+T),p);T<8?(T=d(Math.pow(p,T)),w=w.j(T).add(d(_))):(w=w.j(y),w=w.add(d(_)))}return w}var g=l(0),E=l(1),V=l(16777216);r=a.prototype,r.m=function(){if(k(this))return-M(this).m();let I=0,p=1;for(let y=0;y<this.g.length;y++){const w=this.i(y);I+=(w>=0?w:4294967296+w)*p,p*=4294967296}return I},r.toString=function(I){if(I=I||10,I<2||36<I)throw Error("radix out of range: "+I);if(D(this))return"0";if(k(this))return"-"+M(this).toString(I);const p=d(Math.pow(I,6));var y=this;let w="";for(;;){const T=rt(y,p).g;y=K(y,T.j(p));let b=((y.g.length>0?y.g[0]:y.h)>>>0).toString(I);if(y=T,D(y))return b+w;for(;b.length<6;)b="0"+b;w=b+w}},r.i=function(I){return I<0?0:I<this.g.length?this.g[I]:this.h};function D(I){if(I.h!=0)return!1;for(let p=0;p<I.g.length;p++)if(I.g[p]!=0)return!1;return!0}function k(I){return I.h==-1}r.l=function(I){return I=K(this,I),k(I)?-1:D(I)?0:1};function M(I){const p=I.g.length,y=[];for(let w=0;w<p;w++)y[w]=~I.g[w];return new a(y,~I.h).add(E)}r.abs=function(){return k(this)?M(this):this},r.add=function(I){const p=Math.max(this.g.length,I.g.length),y=[];let w=0;for(let T=0;T<=p;T++){let b=w+(this.i(T)&65535)+(I.i(T)&65535),_=(b>>>16)+(this.i(T)>>>16)+(I.i(T)>>>16);w=_>>>16,b&=65535,_&=65535,y[T]=_<<16|b}return new a(y,y[y.length-1]&-2147483648?-1:0)};function K(I,p){return I.add(M(p))}r.j=function(I){if(D(this)||D(I))return g;if(k(this))return k(I)?M(this).j(M(I)):M(M(this).j(I));if(k(I))return M(this.j(M(I)));if(this.l(V)<0&&I.l(V)<0)return d(this.m()*I.m());const p=this.g.length+I.g.length,y=[];for(var w=0;w<2*p;w++)y[w]=0;for(w=0;w<this.g.length;w++)for(let T=0;T<I.g.length;T++){const b=this.i(w)>>>16,_=this.i(w)&65535,Ct=I.i(T)>>>16,De=I.i(T)&65535;y[2*w+2*T]+=_*De,j(y,2*w+2*T),y[2*w+2*T+1]+=b*De,j(y,2*w+2*T+1),y[2*w+2*T+1]+=_*Ct,j(y,2*w+2*T+1),y[2*w+2*T+2]+=b*Ct,j(y,2*w+2*T+2)}for(I=0;I<p;I++)y[I]=y[2*I+1]<<16|y[2*I];for(I=p;I<2*p;I++)y[I]=0;return new a(y,0)};function j(I,p){for(;(I[p]&65535)!=I[p];)I[p+1]+=I[p]>>>16,I[p]&=65535,p++}function q(I,p){this.g=I,this.h=p}function rt(I,p){if(D(p))throw Error("division by zero");if(D(I))return new q(g,g);if(k(I))return p=rt(M(I),p),new q(M(p.g),M(p.h));if(k(p))return p=rt(I,M(p)),new q(M(p.g),p.h);if(I.g.length>30){if(k(I)||k(p))throw Error("slowDivide_ only works with positive integers.");for(var y=E,w=p;w.l(I)<=0;)y=W(y),w=W(w);var T=J(y,1),b=J(w,1);for(w=J(w,2),y=J(y,2);!D(w);){var _=b.add(w);_.l(I)<=0&&(T=T.add(y),b=_),w=J(w,1),y=J(y,1)}return p=K(I,T.j(p)),new q(T,p)}for(T=g;I.l(p)>=0;){for(y=Math.max(1,Math.floor(I.m()/p.m())),w=Math.ceil(Math.log(y)/Math.LN2),w=w<=48?1:Math.pow(2,w-48),b=d(y),_=b.j(p);k(_)||_.l(I)>0;)y-=w,b=d(y),_=b.j(p);D(b)&&(b=E),T=T.add(b),I=K(I,_)}return new q(T,I)}r.B=function(I){return rt(this,I).h},r.and=function(I){const p=Math.max(this.g.length,I.g.length),y=[];for(let w=0;w<p;w++)y[w]=this.i(w)&I.i(w);return new a(y,this.h&I.h)},r.or=function(I){const p=Math.max(this.g.length,I.g.length),y=[];for(let w=0;w<p;w++)y[w]=this.i(w)|I.i(w);return new a(y,this.h|I.h)},r.xor=function(I){const p=Math.max(this.g.length,I.g.length),y=[];for(let w=0;w<p;w++)y[w]=this.i(w)^I.i(w);return new a(y,this.h^I.h)};function W(I){const p=I.g.length+1,y=[];for(let w=0;w<p;w++)y[w]=I.i(w)<<1|I.i(w-1)>>>31;return new a(y,I.h)}function J(I,p){const y=p>>5;p%=32;const w=I.g.length-y,T=[];for(let b=0;b<w;b++)T[b]=p>0?I.i(b+y)>>>p|I.i(b+y+1)<<32-p:I.i(b+y);return new a(T,I.h)}n.prototype.digest=n.prototype.A,n.prototype.reset=n.prototype.u,n.prototype.update=n.prototype.v,$l=n,a.prototype.add=a.prototype.add,a.prototype.multiply=a.prototype.j,a.prototype.modulo=a.prototype.B,a.prototype.compare=a.prototype.l,a.prototype.toNumber=a.prototype.m,a.prototype.toString=a.prototype.toString,a.prototype.getBits=a.prototype.i,a.fromNumber=d,a.fromString=f,Ie=a}).apply(typeof ic<"u"?ic:typeof self<"u"?self:typeof window<"u"?window:{});var Ts=typeof globalThis<"u"?globalThis:typeof window<"u"?window:typeof global<"u"?global:typeof self<"u"?self:{};/** @license
Copyright The Closure Library Authors.
SPDX-License-Identifier: Apache-2.0
*/var Gl,_r,Kl,Vs,Ao,Hl,Ql,Wl;(function(){var r,t=Object.defineProperty;function e(o){o=[typeof globalThis=="object"&&globalThis,o,typeof window=="object"&&window,typeof self=="object"&&self,typeof Ts=="object"&&Ts];for(var c=0;c<o.length;++c){var h=o[c];if(h&&h.Math==Math)return h}throw Error("Cannot find global object")}var n=e(this);function s(o,c){if(c)t:{var h=n;o=o.split(".");for(var m=0;m<o.length-1;m++){var A=o[m];if(!(A in h))break t;h=h[A]}o=o[o.length-1],m=h[o],c=c(m),c!=m&&c!=null&&t(h,o,{configurable:!0,writable:!0,value:c})}}s("Symbol.dispose",function(o){return o||Symbol("Symbol.dispose")}),s("Array.prototype.values",function(o){return o||function(){return this[Symbol.iterator]()}}),s("Object.entries",function(o){return o||function(c){var h=[],m;for(m in c)Object.prototype.hasOwnProperty.call(c,m)&&h.push([m,c[m]]);return h}});/** @license

 Copyright The Closure Library Authors.
 SPDX-License-Identifier: Apache-2.0
*/var i=i||{},a=this||self;function u(o){var c=typeof o;return c=="object"&&o!=null||c=="function"}function l(o,c,h){return o.call.apply(o.bind,arguments)}function d(o,c,h){return d=l,d.apply(null,arguments)}function f(o,c){var h=Array.prototype.slice.call(arguments,1);return function(){var m=h.slice();return m.push.apply(m,arguments),o.apply(this,m)}}function g(o,c){function h(){}h.prototype=c.prototype,o.Z=c.prototype,o.prototype=new h,o.prototype.constructor=o,o.Ob=function(m,A,R){for(var x=Array(arguments.length-2),z=2;z<arguments.length;z++)x[z-2]=arguments[z];return c.prototype[A].apply(m,x)}}var E=typeof AsyncContext<"u"&&typeof AsyncContext.Snapshot=="function"?o=>o&&AsyncContext.Snapshot.wrap(o):o=>o;function V(o){const c=o.length;if(c>0){const h=Array(c);for(let m=0;m<c;m++)h[m]=o[m];return h}return[]}function D(o,c){for(let m=1;m<arguments.length;m++){const A=arguments[m];var h=typeof A;if(h=h!="object"?h:A?Array.isArray(A)?"array":h:"null",h=="array"||h=="object"&&typeof A.length=="number"){h=o.length||0;const R=A.length||0;o.length=h+R;for(let x=0;x<R;x++)o[h+x]=A[x]}else o.push(A)}}class k{constructor(c,h){this.i=c,this.j=h,this.h=0,this.g=null}get(){let c;return this.h>0?(this.h--,c=this.g,this.g=c.next,c.next=null):c=this.i(),c}}function M(o){a.setTimeout(()=>{throw o},0)}function K(){var o=I;let c=null;return o.g&&(c=o.g,o.g=o.g.next,o.g||(o.h=null),c.next=null),c}class j{constructor(){this.h=this.g=null}add(c,h){const m=q.get();m.set(c,h),this.h?this.h.next=m:this.g=m,this.h=m}}var q=new k(()=>new rt,o=>o.reset());class rt{constructor(){this.next=this.g=this.h=null}set(c,h){this.h=c,this.g=h,this.next=null}reset(){this.next=this.g=this.h=null}}let W,J=!1,I=new j,p=()=>{const o=Promise.resolve(void 0);W=()=>{o.then(y)}};function y(){for(var o;o=K();){try{o.h.call(o.g)}catch(h){M(h)}var c=q;c.j(o),c.h<100&&(c.h++,o.next=c.g,c.g=o)}J=!1}function w(){this.u=this.u,this.C=this.C}w.prototype.u=!1,w.prototype.dispose=function(){this.u||(this.u=!0,this.N())},w.prototype[Symbol.dispose]=function(){this.dispose()},w.prototype.N=function(){if(this.C)for(;this.C.length;)this.C.shift()()};function T(o,c){this.type=o,this.g=this.target=c,this.defaultPrevented=!1}T.prototype.h=function(){this.defaultPrevented=!0};var b=(function(){if(!a.addEventListener||!Object.defineProperty)return!1;var o=!1,c=Object.defineProperty({},"passive",{get:function(){o=!0}});try{const h=()=>{};a.addEventListener("test",h,c),a.removeEventListener("test",h,c)}catch{}return o})();function _(o){return/^[\s\xa0]*$/.test(o)}function Ct(o,c){T.call(this,o?o.type:""),this.relatedTarget=this.g=this.target=null,this.button=this.screenY=this.screenX=this.clientY=this.clientX=0,this.key="",this.metaKey=this.shiftKey=this.altKey=this.ctrlKey=!1,this.state=null,this.pointerId=0,this.pointerType="",this.i=null,o&&this.init(o,c)}g(Ct,T),Ct.prototype.init=function(o,c){const h=this.type=o.type,m=o.changedTouches&&o.changedTouches.length?o.changedTouches[0]:null;this.target=o.target||o.srcElement,this.g=c,c=o.relatedTarget,c||(h=="mouseover"?c=o.fromElement:h=="mouseout"&&(c=o.toElement)),this.relatedTarget=c,m?(this.clientX=m.clientX!==void 0?m.clientX:m.pageX,this.clientY=m.clientY!==void 0?m.clientY:m.pageY,this.screenX=m.screenX||0,this.screenY=m.screenY||0):(this.clientX=o.clientX!==void 0?o.clientX:o.pageX,this.clientY=o.clientY!==void 0?o.clientY:o.pageY,this.screenX=o.screenX||0,this.screenY=o.screenY||0),this.button=o.button,this.key=o.key||"",this.ctrlKey=o.ctrlKey,this.altKey=o.altKey,this.shiftKey=o.shiftKey,this.metaKey=o.metaKey,this.pointerId=o.pointerId||0,this.pointerType=o.pointerType,this.state=o.state,this.i=o,o.defaultPrevented&&Ct.Z.h.call(this)},Ct.prototype.h=function(){Ct.Z.h.call(this);const o=this.i;o.preventDefault?o.preventDefault():o.returnValue=!1};var De="closure_listenable_"+(Math.random()*1e6|0),yf=0;function If(o,c,h,m,A){this.listener=o,this.proxy=null,this.src=c,this.type=h,this.capture=!!m,this.ha=A,this.key=++yf,this.da=this.fa=!1}function os(o){o.da=!0,o.listener=null,o.proxy=null,o.src=null,o.ha=null}function as(o,c,h){for(const m in o)c.call(h,o[m],m,o)}function Ef(o,c){for(const h in o)c.call(void 0,o[h],h,o)}function Qa(o){const c={};for(const h in o)c[h]=o[h];return c}const Wa="constructor hasOwnProperty isPrototypeOf propertyIsEnumerable toLocaleString toString valueOf".split(" ");function Ja(o,c){let h,m;for(let A=1;A<arguments.length;A++){m=arguments[A];for(h in m)o[h]=m[h];for(let R=0;R<Wa.length;R++)h=Wa[R],Object.prototype.hasOwnProperty.call(m,h)&&(o[h]=m[h])}}function us(o){this.src=o,this.g={},this.h=0}us.prototype.add=function(o,c,h,m,A){const R=o.toString();o=this.g[R],o||(o=this.g[R]=[],this.h++);const x=ki(o,c,m,A);return x>-1?(c=o[x],h||(c.fa=!1)):(c=new If(c,this.src,R,!!m,A),c.fa=h,o.push(c)),c};function Ni(o,c){const h=c.type;if(h in o.g){var m=o.g[h],A=Array.prototype.indexOf.call(m,c,void 0),R;(R=A>=0)&&Array.prototype.splice.call(m,A,1),R&&(os(c),o.g[h].length==0&&(delete o.g[h],o.h--))}}function ki(o,c,h,m){for(let A=0;A<o.length;++A){const R=o[A];if(!R.da&&R.listener==c&&R.capture==!!h&&R.ha==m)return A}return-1}var Mi="closure_lm_"+(Math.random()*1e6|0),Oi={};function Ya(o,c,h,m,A){if(Array.isArray(c)){for(let R=0;R<c.length;R++)Ya(o,c[R],h,m,A);return null}return h=tu(h),o&&o[De]?o.J(c,h,u(m)?!!m.capture:!1,A):Tf(o,c,h,!1,m,A)}function Tf(o,c,h,m,A,R){if(!c)throw Error("Invalid event type");const x=u(A)?!!A.capture:!!A;let z=Li(o);if(z||(o[Mi]=z=new us(o)),h=z.add(c,h,m,x,R),h.proxy)return h;if(m=wf(),h.proxy=m,m.src=o,m.listener=h,o.addEventListener)b||(A=x),A===void 0&&(A=!1),o.addEventListener(c.toString(),m,A);else if(o.attachEvent)o.attachEvent(Za(c.toString()),m);else if(o.addListener&&o.removeListener)o.addListener(m);else throw Error("addEventListener and attachEvent are unavailable.");return h}function wf(){function o(h){return c.call(o.src,o.listener,h)}const c=vf;return o}function Xa(o,c,h,m,A){if(Array.isArray(c))for(var R=0;R<c.length;R++)Xa(o,c[R],h,m,A);else m=u(m)?!!m.capture:!!m,h=tu(h),o&&o[De]?(o=o.i,R=String(c).toString(),R in o.g&&(c=o.g[R],h=ki(c,h,m,A),h>-1&&(os(c[h]),Array.prototype.splice.call(c,h,1),c.length==0&&(delete o.g[R],o.h--)))):o&&(o=Li(o))&&(c=o.g[c.toString()],o=-1,c&&(o=ki(c,h,m,A)),(h=o>-1?c[o]:null)&&Fi(h))}function Fi(o){if(typeof o!="number"&&o&&!o.da){var c=o.src;if(c&&c[De])Ni(c.i,o);else{var h=o.type,m=o.proxy;c.removeEventListener?c.removeEventListener(h,m,o.capture):c.detachEvent?c.detachEvent(Za(h),m):c.addListener&&c.removeListener&&c.removeListener(m),(h=Li(c))?(Ni(h,o),h.h==0&&(h.src=null,c[Mi]=null)):os(o)}}}function Za(o){return o in Oi?Oi[o]:Oi[o]="on"+o}function vf(o,c){if(o.da)o=!0;else{c=new Ct(c,this);const h=o.listener,m=o.ha||o.src;o.fa&&Fi(o),o=h.call(m,c)}return o}function Li(o){return o=o[Mi],o instanceof us?o:null}var Bi="__closure_events_fn_"+(Math.random()*1e9>>>0);function tu(o){return typeof o=="function"?o:(o[Bi]||(o[Bi]=function(c){return o.handleEvent(c)}),o[Bi])}function Tt(){w.call(this),this.i=new us(this),this.M=this,this.G=null}g(Tt,w),Tt.prototype[De]=!0,Tt.prototype.removeEventListener=function(o,c,h,m){Xa(this,o,c,h,m)};function St(o,c){var h,m=o.G;if(m)for(h=[];m;m=m.G)h.push(m);if(o=o.M,m=c.type||c,typeof c=="string")c=new T(c,o);else if(c instanceof T)c.target=c.target||o;else{var A=c;c=new T(m,o),Ja(c,A)}A=!0;let R,x;if(h)for(x=h.length-1;x>=0;x--)R=c.g=h[x],A=cs(R,m,!0,c)&&A;if(R=c.g=o,A=cs(R,m,!0,c)&&A,A=cs(R,m,!1,c)&&A,h)for(x=0;x<h.length;x++)R=c.g=h[x],A=cs(R,m,!1,c)&&A}Tt.prototype.N=function(){if(Tt.Z.N.call(this),this.i){var o=this.i;for(const c in o.g){const h=o.g[c];for(let m=0;m<h.length;m++)os(h[m]);delete o.g[c],o.h--}}this.G=null},Tt.prototype.J=function(o,c,h,m){return this.i.add(String(o),c,!1,h,m)},Tt.prototype.K=function(o,c,h,m){return this.i.add(String(o),c,!0,h,m)};function cs(o,c,h,m){if(c=o.i.g[String(c)],!c)return!0;c=c.concat();let A=!0;for(let R=0;R<c.length;++R){const x=c[R];if(x&&!x.da&&x.capture==h){const z=x.listener,gt=x.ha||x.src;x.fa&&Ni(o.i,x),A=z.call(gt,m)!==!1&&A}}return A&&!m.defaultPrevented}function Af(o,c){if(typeof o!="function")if(o&&typeof o.handleEvent=="function")o=d(o.handleEvent,o);else throw Error("Invalid listener argument");return Number(c)>2147483647?-1:a.setTimeout(o,c||0)}function eu(o){o.g=Af(()=>{o.g=null,o.i&&(o.i=!1,eu(o))},o.l);const c=o.h;o.h=null,o.m.apply(null,c)}class bf extends w{constructor(c,h){super(),this.m=c,this.l=h,this.h=null,this.i=!1,this.g=null}j(c){this.h=arguments,this.g?this.i=!0:eu(this)}N(){super.N(),this.g&&(a.clearTimeout(this.g),this.g=null,this.i=!1,this.h=null)}}function Wn(o){w.call(this),this.h=o,this.g={}}g(Wn,w);var nu=[];function ru(o){as(o.g,function(c,h){this.g.hasOwnProperty(h)&&Fi(c)},o),o.g={}}Wn.prototype.N=function(){Wn.Z.N.call(this),ru(this)},Wn.prototype.handleEvent=function(){throw Error("EventHandler.handleEvent not implemented")};var Ui=a.JSON.stringify,Rf=a.JSON.parse,Sf=class{stringify(o){return a.JSON.stringify(o,void 0)}parse(o){return a.JSON.parse(o,void 0)}};function su(){}function iu(){}var Jn={OPEN:"a",hb:"b",ERROR:"c",tb:"d"};function qi(){T.call(this,"d")}g(qi,T);function ji(){T.call(this,"c")}g(ji,T);var xe={},ou=null;function ls(){return ou=ou||new Tt}xe.Ia="serverreachability";function au(o){T.call(this,xe.Ia,o)}g(au,T);function Yn(o){const c=ls();St(c,new au(c))}xe.STAT_EVENT="statevent";function uu(o,c){T.call(this,xe.STAT_EVENT,o),this.stat=c}g(uu,T);function Vt(o){const c=ls();St(c,new uu(c,o))}xe.Ja="timingevent";function cu(o,c){T.call(this,xe.Ja,o),this.size=c}g(cu,T);function Xn(o,c){if(typeof o!="function")throw Error("Fn must not be null and must be a function");return a.setTimeout(function(){o()},c)}function Zn(){this.g=!0}Zn.prototype.ua=function(){this.g=!1};function Vf(o,c,h,m,A,R){o.info(function(){if(o.g)if(R){var x="",z=R.split("&");for(let et=0;et<z.length;et++){var gt=z[et].split("=");if(gt.length>1){const yt=gt[0];gt=gt[1];const Gt=yt.split("_");x=Gt.length>=2&&Gt[1]=="type"?x+(yt+"="+gt+"&"):x+(yt+"=redacted&")}}}else x=null;else x=R;return"XMLHTTP REQ ("+m+") [attempt "+A+"]: "+c+`
`+h+`
`+x})}function Pf(o,c,h,m,A,R,x){o.info(function(){return"XMLHTTP RESP ("+m+") [ attempt "+A+"]: "+c+`
`+h+`
`+R+" "+x})}function on(o,c,h,m){o.info(function(){return"XMLHTTP TEXT ("+c+"): "+Df(o,h)+(m?" "+m:"")})}function Cf(o,c){o.info(function(){return"TIMEOUT: "+c})}Zn.prototype.info=function(){};function Df(o,c){if(!o.g)return c;if(!c)return null;try{const R=JSON.parse(c);if(R){for(o=0;o<R.length;o++)if(Array.isArray(R[o])){var h=R[o];if(!(h.length<2)){var m=h[1];if(Array.isArray(m)&&!(m.length<1)){var A=m[0];if(A!="noop"&&A!="stop"&&A!="close")for(let x=1;x<m.length;x++)m[x]=""}}}}return Ui(R)}catch{return c}}var hs={NO_ERROR:0,cb:1,qb:2,pb:3,kb:4,ob:5,rb:6,Ga:7,TIMEOUT:8,ub:9},lu={ib:"complete",Fb:"success",ERROR:"error",Ga:"abort",xb:"ready",yb:"readystatechange",TIMEOUT:"timeout",sb:"incrementaldata",wb:"progress",lb:"downloadprogress",Nb:"uploadprogress"},hu;function zi(){}g(zi,su),zi.prototype.g=function(){return new XMLHttpRequest},hu=new zi;function tr(o){return encodeURIComponent(String(o))}function xf(o){var c=1;o=o.split(":");const h=[];for(;c>0&&o.length;)h.push(o.shift()),c--;return o.length&&h.push(o.join(":")),h}function oe(o,c,h,m){this.j=o,this.i=c,this.l=h,this.S=m||1,this.V=new Wn(this),this.H=45e3,this.J=null,this.o=!1,this.u=this.B=this.A=this.M=this.F=this.T=this.D=null,this.G=[],this.g=null,this.C=0,this.m=this.v=null,this.X=-1,this.K=!1,this.P=0,this.O=null,this.W=this.L=this.U=this.R=!1,this.h=new du}function du(){this.i=null,this.g="",this.h=!1}var fu={},$i={};function Gi(o,c,h){o.M=1,o.A=fs($t(c)),o.u=h,o.R=!0,mu(o,null)}function mu(o,c){o.F=Date.now(),ds(o),o.B=$t(o.A);var h=o.B,m=o.S;Array.isArray(m)||(m=[String(m)]),Su(h.i,"t",m),o.C=0,h=o.j.L,o.h=new du,o.g=Gu(o.j,h?c:null,!o.u),o.P>0&&(o.O=new bf(d(o.Y,o,o.g),o.P)),c=o.V,h=o.g,m=o.ba;var A="readystatechange";Array.isArray(A)||(A&&(nu[0]=A.toString()),A=nu);for(let R=0;R<A.length;R++){const x=Ya(h,A[R],m||c.handleEvent,!1,c.h||c);if(!x)break;c.g[x.key]=x}c=o.J?Qa(o.J):{},o.u?(o.v||(o.v="POST"),c["Content-Type"]="application/x-www-form-urlencoded",o.g.ea(o.B,o.v,o.u,c)):(o.v="GET",o.g.ea(o.B,o.v,null,c)),Yn(),Vf(o.i,o.v,o.B,o.l,o.S,o.u)}oe.prototype.ba=function(o){o=o.target;const c=this.O;c&&ce(o)==3?c.j():this.Y(o)},oe.prototype.Y=function(o){try{if(o==this.g)t:{const z=ce(this.g),gt=this.g.ya(),et=this.g.ca();if(!(z<3)&&(z!=3||this.g&&(this.h.h||this.g.la()||ku(this.g)))){this.K||z!=4||gt==7||(gt==8||et<=0?Yn(3):Yn(2)),Ki(this);var c=this.g.ca();this.X=c;var h=Nf(this);if(this.o=c==200,Pf(this.i,this.v,this.B,this.l,this.S,z,c),this.o){if(this.U&&!this.L){e:{if(this.g){var m,A=this.g;if((m=A.g?A.g.getResponseHeader("X-HTTP-Initial-Response"):null)&&!_(m)){var R=m;break e}}R=null}if(o=R)on(this.i,this.l,o,"Initial handshake response via X-HTTP-Initial-Response"),this.L=!0,Hi(this,o);else{this.o=!1,this.m=3,Vt(12),Ne(this),er(this);break t}}if(this.R){o=!0;let yt;for(;!this.K&&this.C<h.length;)if(yt=kf(this,h),yt==$i){z==4&&(this.m=4,Vt(14),o=!1),on(this.i,this.l,null,"[Incomplete Response]");break}else if(yt==fu){this.m=4,Vt(15),on(this.i,this.l,h,"[Invalid Chunk]"),o=!1;break}else on(this.i,this.l,yt,null),Hi(this,yt);if(gu(this)&&this.C!=0&&(this.h.g=this.h.g.slice(this.C),this.C=0),z!=4||h.length!=0||this.h.h||(this.m=1,Vt(16),o=!1),this.o=this.o&&o,!o)on(this.i,this.l,h,"[Invalid Chunked Response]"),Ne(this),er(this);else if(h.length>0&&!this.W){this.W=!0;var x=this.j;x.g==this&&x.aa&&!x.P&&(x.j.info("Great, no buffering proxy detected. Bytes received: "+h.length),eo(x),x.P=!0,Vt(11))}}else on(this.i,this.l,h,null),Hi(this,h);z==4&&Ne(this),this.o&&!this.K&&(z==4?qu(this.j,this):(this.o=!1,ds(this)))}else Qf(this.g),c==400&&h.indexOf("Unknown SID")>0?(this.m=3,Vt(12)):(this.m=0,Vt(13)),Ne(this),er(this)}}}catch{}};function Nf(o){if(!gu(o))return o.g.la();const c=ku(o.g);if(c==="")return"";let h="";const m=c.length,A=ce(o.g)==4;if(!o.h.i){if(typeof TextDecoder>"u")return Ne(o),er(o),"";o.h.i=new a.TextDecoder}for(let R=0;R<m;R++)o.h.h=!0,h+=o.h.i.decode(c[R],{stream:!(A&&R==m-1)});return c.length=0,o.h.g+=h,o.C=0,o.h.g}function gu(o){return o.g?o.v=="GET"&&o.M!=2&&o.j.Aa:!1}function kf(o,c){var h=o.C,m=c.indexOf(`
`,h);return m==-1?$i:(h=Number(c.substring(h,m)),isNaN(h)?fu:(m+=1,m+h>c.length?$i:(c=c.slice(m,m+h),o.C=m+h,c)))}oe.prototype.cancel=function(){this.K=!0,Ne(this)};function ds(o){o.T=Date.now()+o.H,pu(o,o.H)}function pu(o,c){if(o.D!=null)throw Error("WatchDog timer not null");o.D=Xn(d(o.aa,o),c)}function Ki(o){o.D&&(a.clearTimeout(o.D),o.D=null)}oe.prototype.aa=function(){this.D=null;const o=Date.now();o-this.T>=0?(Cf(this.i,this.B),this.M!=2&&(Yn(),Vt(17)),Ne(this),this.m=2,er(this)):pu(this,this.T-o)};function er(o){o.j.I==0||o.K||qu(o.j,o)}function Ne(o){Ki(o);var c=o.O;c&&typeof c.dispose=="function"&&c.dispose(),o.O=null,ru(o.V),o.g&&(c=o.g,o.g=null,c.abort(),c.dispose())}function Hi(o,c){try{var h=o.j;if(h.I!=0&&(h.g==o||Qi(h.h,o))){if(!o.L&&Qi(h.h,o)&&h.I==3){try{var m=h.Ba.g.parse(c)}catch{m=null}if(Array.isArray(m)&&m.length==3){var A=m;if(A[0]==0){t:if(!h.v){if(h.g)if(h.g.F+3e3<o.F)ys(h),ps(h);else break t;to(h),Vt(18)}}else h.xa=A[1],0<h.xa-h.K&&A[2]<37500&&h.F&&h.A==0&&!h.C&&(h.C=Xn(d(h.Va,h),6e3));Iu(h.h)<=1&&h.ta&&(h.ta=void 0)}else Me(h,11)}else if((o.L||h.g==o)&&ys(h),!_(c))for(A=h.Ba.g.parse(c),c=0;c<A.length;c++){let et=A[c];const yt=et[0];if(!(yt<=h.K))if(h.K=yt,et=et[1],h.I==2)if(et[0]=="c"){h.M=et[1],h.ba=et[2];const Gt=et[3];Gt!=null&&(h.ka=Gt,h.j.info("VER="+h.ka));const Oe=et[4];Oe!=null&&(h.za=Oe,h.j.info("SVER="+h.za));const le=et[5];le!=null&&typeof le=="number"&&le>0&&(m=1.5*le,h.O=m,h.j.info("backChannelRequestTimeoutMs_="+m)),m=h;const he=o.g;if(he){const Es=he.g?he.g.getResponseHeader("X-Client-Wire-Protocol"):null;if(Es){var R=m.h;R.g||Es.indexOf("spdy")==-1&&Es.indexOf("quic")==-1&&Es.indexOf("h2")==-1||(R.j=R.l,R.g=new Set,R.h&&(Wi(R,R.h),R.h=null))}if(m.G){const no=he.g?he.g.getResponseHeader("X-HTTP-Session-Id"):null;no&&(m.wa=no,st(m.J,m.G,no))}}h.I=3,h.l&&h.l.ra(),h.aa&&(h.T=Date.now()-o.F,h.j.info("Handshake RTT: "+h.T+"ms")),m=h;var x=o;if(m.na=$u(m,m.L?m.ba:null,m.W),x.L){Eu(m.h,x);var z=x,gt=m.O;gt&&(z.H=gt),z.D&&(Ki(z),ds(z)),m.g=x}else Bu(m);h.i.length>0&&_s(h)}else et[0]!="stop"&&et[0]!="close"||Me(h,7);else h.I==3&&(et[0]=="stop"||et[0]=="close"?et[0]=="stop"?Me(h,7):Zi(h):et[0]!="noop"&&h.l&&h.l.qa(et),h.A=0)}}Yn(4)}catch{}}var Mf=class{constructor(o,c){this.g=o,this.map=c}};function _u(o){this.l=o||10,a.PerformanceNavigationTiming?(o=a.performance.getEntriesByType("navigation"),o=o.length>0&&(o[0].nextHopProtocol=="hq"||o[0].nextHopProtocol=="h2")):o=!!(a.chrome&&a.chrome.loadTimes&&a.chrome.loadTimes()&&a.chrome.loadTimes().wasFetchedViaSpdy),this.j=o?this.l:1,this.g=null,this.j>1&&(this.g=new Set),this.h=null,this.i=[]}function yu(o){return o.h?!0:o.g?o.g.size>=o.j:!1}function Iu(o){return o.h?1:o.g?o.g.size:0}function Qi(o,c){return o.h?o.h==c:o.g?o.g.has(c):!1}function Wi(o,c){o.g?o.g.add(c):o.h=c}function Eu(o,c){o.h&&o.h==c?o.h=null:o.g&&o.g.has(c)&&o.g.delete(c)}_u.prototype.cancel=function(){if(this.i=Tu(this),this.h)this.h.cancel(),this.h=null;else if(this.g&&this.g.size!==0){for(const o of this.g.values())o.cancel();this.g.clear()}};function Tu(o){if(o.h!=null)return o.i.concat(o.h.G);if(o.g!=null&&o.g.size!==0){let c=o.i;for(const h of o.g.values())c=c.concat(h.G);return c}return V(o.i)}var wu=RegExp("^(?:([^:/?#.]+):)?(?://(?:([^\\\\/?#]*)@)?([^\\\\/?#]*?)(?::([0-9]+))?(?=[\\\\/?#]|$))?([^?#]+)?(?:\\?([^#]*))?(?:#([\\s\\S]*))?$");function Of(o,c){if(o){o=o.split("&");for(let h=0;h<o.length;h++){const m=o[h].indexOf("=");let A,R=null;m>=0?(A=o[h].substring(0,m),R=o[h].substring(m+1)):A=o[h],c(A,R?decodeURIComponent(R.replace(/\+/g," ")):"")}}}function ae(o){this.g=this.o=this.j="",this.u=null,this.m=this.h="",this.l=!1;let c;o instanceof ae?(this.l=o.l,nr(this,o.j),this.o=o.o,this.g=o.g,rr(this,o.u),this.h=o.h,Ji(this,Vu(o.i)),this.m=o.m):o&&(c=String(o).match(wu))?(this.l=!1,nr(this,c[1]||"",!0),this.o=sr(c[2]||""),this.g=sr(c[3]||"",!0),rr(this,c[4]),this.h=sr(c[5]||"",!0),Ji(this,c[6]||"",!0),this.m=sr(c[7]||"")):(this.l=!1,this.i=new or(null,this.l))}ae.prototype.toString=function(){const o=[];var c=this.j;c&&o.push(ir(c,vu,!0),":");var h=this.g;return(h||c=="file")&&(o.push("//"),(c=this.o)&&o.push(ir(c,vu,!0),"@"),o.push(tr(h).replace(/%25([0-9a-fA-F]{2})/g,"%$1")),h=this.u,h!=null&&o.push(":",String(h))),(h=this.h)&&(this.g&&h.charAt(0)!="/"&&o.push("/"),o.push(ir(h,h.charAt(0)=="/"?Bf:Lf,!0))),(h=this.i.toString())&&o.push("?",h),(h=this.m)&&o.push("#",ir(h,qf)),o.join("")},ae.prototype.resolve=function(o){const c=$t(this);let h=!!o.j;h?nr(c,o.j):h=!!o.o,h?c.o=o.o:h=!!o.g,h?c.g=o.g:h=o.u!=null;var m=o.h;if(h)rr(c,o.u);else if(h=!!o.h){if(m.charAt(0)!="/")if(this.g&&!this.h)m="/"+m;else{var A=c.h.lastIndexOf("/");A!=-1&&(m=c.h.slice(0,A+1)+m)}if(A=m,A==".."||A==".")m="";else if(A.indexOf("./")!=-1||A.indexOf("/.")!=-1){m=A.lastIndexOf("/",0)==0,A=A.split("/");const R=[];for(let x=0;x<A.length;){const z=A[x++];z=="."?m&&x==A.length&&R.push(""):z==".."?((R.length>1||R.length==1&&R[0]!="")&&R.pop(),m&&x==A.length&&R.push("")):(R.push(z),m=!0)}m=R.join("/")}else m=A}return h?c.h=m:h=o.i.toString()!=="",h?Ji(c,Vu(o.i)):h=!!o.m,h&&(c.m=o.m),c};function $t(o){return new ae(o)}function nr(o,c,h){o.j=h?sr(c,!0):c,o.j&&(o.j=o.j.replace(/:$/,""))}function rr(o,c){if(c){if(c=Number(c),isNaN(c)||c<0)throw Error("Bad port number "+c);o.u=c}else o.u=null}function Ji(o,c,h){c instanceof or?(o.i=c,jf(o.i,o.l)):(h||(c=ir(c,Uf)),o.i=new or(c,o.l))}function st(o,c,h){o.i.set(c,h)}function fs(o){return st(o,"zx",Math.floor(Math.random()*2147483648).toString(36)+Math.abs(Math.floor(Math.random()*2147483648)^Date.now()).toString(36)),o}function sr(o,c){return o?c?decodeURI(o.replace(/%25/g,"%2525")):decodeURIComponent(o):""}function ir(o,c,h){return typeof o=="string"?(o=encodeURI(o).replace(c,Ff),h&&(o=o.replace(/%25([0-9a-fA-F]{2})/g,"%$1")),o):null}function Ff(o){return o=o.charCodeAt(0),"%"+(o>>4&15).toString(16)+(o&15).toString(16)}var vu=/[#\/\?@]/g,Lf=/[#\?:]/g,Bf=/[#\?]/g,Uf=/[#\?@]/g,qf=/#/g;function or(o,c){this.h=this.g=null,this.i=o||null,this.j=!!c}function ke(o){o.g||(o.g=new Map,o.h=0,o.i&&Of(o.i,function(c,h){o.add(decodeURIComponent(c.replace(/\+/g," ")),h)}))}r=or.prototype,r.add=function(o,c){ke(this),this.i=null,o=an(this,o);let h=this.g.get(o);return h||this.g.set(o,h=[]),h.push(c),this.h+=1,this};function Au(o,c){ke(o),c=an(o,c),o.g.has(c)&&(o.i=null,o.h-=o.g.get(c).length,o.g.delete(c))}function bu(o,c){return ke(o),c=an(o,c),o.g.has(c)}r.forEach=function(o,c){ke(this),this.g.forEach(function(h,m){h.forEach(function(A){o.call(c,A,m,this)},this)},this)};function Ru(o,c){ke(o);let h=[];if(typeof c=="string")bu(o,c)&&(h=h.concat(o.g.get(an(o,c))));else for(o=Array.from(o.g.values()),c=0;c<o.length;c++)h=h.concat(o[c]);return h}r.set=function(o,c){return ke(this),this.i=null,o=an(this,o),bu(this,o)&&(this.h-=this.g.get(o).length),this.g.set(o,[c]),this.h+=1,this},r.get=function(o,c){return o?(o=Ru(this,o),o.length>0?String(o[0]):c):c};function Su(o,c,h){Au(o,c),h.length>0&&(o.i=null,o.g.set(an(o,c),V(h)),o.h+=h.length)}r.toString=function(){if(this.i)return this.i;if(!this.g)return"";const o=[],c=Array.from(this.g.keys());for(let m=0;m<c.length;m++){var h=c[m];const A=tr(h);h=Ru(this,h);for(let R=0;R<h.length;R++){let x=A;h[R]!==""&&(x+="="+tr(h[R])),o.push(x)}}return this.i=o.join("&")};function Vu(o){const c=new or;return c.i=o.i,o.g&&(c.g=new Map(o.g),c.h=o.h),c}function an(o,c){return c=String(c),o.j&&(c=c.toLowerCase()),c}function jf(o,c){c&&!o.j&&(ke(o),o.i=null,o.g.forEach(function(h,m){const A=m.toLowerCase();m!=A&&(Au(this,m),Su(this,A,h))},o)),o.j=c}function zf(o,c){const h=new Zn;if(a.Image){const m=new Image;m.onload=f(ue,h,"TestLoadImage: loaded",!0,c,m),m.onerror=f(ue,h,"TestLoadImage: error",!1,c,m),m.onabort=f(ue,h,"TestLoadImage: abort",!1,c,m),m.ontimeout=f(ue,h,"TestLoadImage: timeout",!1,c,m),a.setTimeout(function(){m.ontimeout&&m.ontimeout()},1e4),m.src=o}else c(!1)}function $f(o,c){const h=new Zn,m=new AbortController,A=setTimeout(()=>{m.abort(),ue(h,"TestPingServer: timeout",!1,c)},1e4);fetch(o,{signal:m.signal}).then(R=>{clearTimeout(A),R.ok?ue(h,"TestPingServer: ok",!0,c):ue(h,"TestPingServer: server error",!1,c)}).catch(()=>{clearTimeout(A),ue(h,"TestPingServer: error",!1,c)})}function ue(o,c,h,m,A){try{A&&(A.onload=null,A.onerror=null,A.onabort=null,A.ontimeout=null),m(h)}catch{}}function Gf(){this.g=new Sf}function Yi(o){this.i=o.Sb||null,this.h=o.ab||!1}g(Yi,su),Yi.prototype.g=function(){return new ms(this.i,this.h)};function ms(o,c){Tt.call(this),this.H=o,this.o=c,this.m=void 0,this.status=this.readyState=0,this.responseType=this.responseText=this.response=this.statusText="",this.onreadystatechange=null,this.A=new Headers,this.h=null,this.F="GET",this.D="",this.g=!1,this.B=this.j=this.l=null,this.v=new AbortController}g(ms,Tt),r=ms.prototype,r.open=function(o,c){if(this.readyState!=0)throw this.abort(),Error("Error reopening a connection");this.F=o,this.D=c,this.readyState=1,ur(this)},r.send=function(o){if(this.readyState!=1)throw this.abort(),Error("need to call open() first. ");if(this.v.signal.aborted)throw this.abort(),Error("Request was aborted.");this.g=!0;const c={headers:this.A,method:this.F,credentials:this.m,cache:void 0,signal:this.v.signal};o&&(c.body=o),(this.H||a).fetch(new Request(this.D,c)).then(this.Pa.bind(this),this.ga.bind(this))},r.abort=function(){this.response=this.responseText="",this.A=new Headers,this.status=0,this.v.abort(),this.j&&this.j.cancel("Request was aborted.").catch(()=>{}),this.readyState>=1&&this.g&&this.readyState!=4&&(this.g=!1,ar(this)),this.readyState=0},r.Pa=function(o){if(this.g&&(this.l=o,this.h||(this.status=this.l.status,this.statusText=this.l.statusText,this.h=o.headers,this.readyState=2,ur(this)),this.g&&(this.readyState=3,ur(this),this.g)))if(this.responseType==="arraybuffer")o.arrayBuffer().then(this.Na.bind(this),this.ga.bind(this));else if(typeof a.ReadableStream<"u"&&"body"in o){if(this.j=o.body.getReader(),this.o){if(this.responseType)throw Error('responseType must be empty for "streamBinaryChunks" mode responses.');this.response=[]}else this.response=this.responseText="",this.B=new TextDecoder;Pu(this)}else o.text().then(this.Oa.bind(this),this.ga.bind(this))};function Pu(o){o.j.read().then(o.Ma.bind(o)).catch(o.ga.bind(o))}r.Ma=function(o){if(this.g){if(this.o&&o.value)this.response.push(o.value);else if(!this.o){var c=o.value?o.value:new Uint8Array(0);(c=this.B.decode(c,{stream:!o.done}))&&(this.response=this.responseText+=c)}o.done?ar(this):ur(this),this.readyState==3&&Pu(this)}},r.Oa=function(o){this.g&&(this.response=this.responseText=o,ar(this))},r.Na=function(o){this.g&&(this.response=o,ar(this))},r.ga=function(){this.g&&ar(this)};function ar(o){o.readyState=4,o.l=null,o.j=null,o.B=null,ur(o)}r.setRequestHeader=function(o,c){this.A.append(o,c)},r.getResponseHeader=function(o){return this.h&&this.h.get(o.toLowerCase())||""},r.getAllResponseHeaders=function(){if(!this.h)return"";const o=[],c=this.h.entries();for(var h=c.next();!h.done;)h=h.value,o.push(h[0]+": "+h[1]),h=c.next();return o.join(`\r
`)};function ur(o){o.onreadystatechange&&o.onreadystatechange.call(o)}Object.defineProperty(ms.prototype,"withCredentials",{get:function(){return this.m==="include"},set:function(o){this.m=o?"include":"same-origin"}});function Cu(o){let c="";return as(o,function(h,m){c+=m,c+=":",c+=h,c+=`\r
`}),c}function Xi(o,c,h){t:{for(m in h){var m=!1;break t}m=!0}m||(h=Cu(h),typeof o=="string"?h!=null&&tr(h):st(o,c,h))}function ut(o){Tt.call(this),this.headers=new Map,this.L=o||null,this.h=!1,this.g=null,this.D="",this.o=0,this.l="",this.j=this.B=this.v=this.A=!1,this.m=null,this.F="",this.H=!1}g(ut,Tt);var Kf=/^https?$/i,Hf=["POST","PUT"];r=ut.prototype,r.Fa=function(o){this.H=o},r.ea=function(o,c,h,m){if(this.g)throw Error("[goog.net.XhrIo] Object is active with another request="+this.D+"; newUri="+o);c=c?c.toUpperCase():"GET",this.D=o,this.l="",this.o=0,this.A=!1,this.h=!0,this.g=this.L?this.L.g():hu.g(),this.g.onreadystatechange=E(d(this.Ca,this));try{this.B=!0,this.g.open(c,String(o),!0),this.B=!1}catch(R){Du(this,R);return}if(o=h||"",h=new Map(this.headers),m)if(Object.getPrototypeOf(m)===Object.prototype)for(var A in m)h.set(A,m[A]);else if(typeof m.keys=="function"&&typeof m.get=="function")for(const R of m.keys())h.set(R,m.get(R));else throw Error("Unknown input type for opt_headers: "+String(m));m=Array.from(h.keys()).find(R=>R.toLowerCase()=="content-type"),A=a.FormData&&o instanceof a.FormData,!(Array.prototype.indexOf.call(Hf,c,void 0)>=0)||m||A||h.set("Content-Type","application/x-www-form-urlencoded;charset=utf-8");for(const[R,x]of h)this.g.setRequestHeader(R,x);this.F&&(this.g.responseType=this.F),"withCredentials"in this.g&&this.g.withCredentials!==this.H&&(this.g.withCredentials=this.H);try{this.m&&(clearTimeout(this.m),this.m=null),this.v=!0,this.g.send(o),this.v=!1}catch(R){Du(this,R)}};function Du(o,c){o.h=!1,o.g&&(o.j=!0,o.g.abort(),o.j=!1),o.l=c,o.o=5,xu(o),gs(o)}function xu(o){o.A||(o.A=!0,St(o,"complete"),St(o,"error"))}r.abort=function(o){this.g&&this.h&&(this.h=!1,this.j=!0,this.g.abort(),this.j=!1,this.o=o||7,St(this,"complete"),St(this,"abort"),gs(this))},r.N=function(){this.g&&(this.h&&(this.h=!1,this.j=!0,this.g.abort(),this.j=!1),gs(this,!0)),ut.Z.N.call(this)},r.Ca=function(){this.u||(this.B||this.v||this.j?Nu(this):this.Xa())},r.Xa=function(){Nu(this)};function Nu(o){if(o.h&&typeof i<"u"){if(o.v&&ce(o)==4)setTimeout(o.Ca.bind(o),0);else if(St(o,"readystatechange"),ce(o)==4){o.h=!1;try{const R=o.ca();t:switch(R){case 200:case 201:case 202:case 204:case 206:case 304:case 1223:var c=!0;break t;default:c=!1}var h;if(!(h=c)){var m;if(m=R===0){let x=String(o.D).match(wu)[1]||null;!x&&a.self&&a.self.location&&(x=a.self.location.protocol.slice(0,-1)),m=!Kf.test(x?x.toLowerCase():"")}h=m}if(h)St(o,"complete"),St(o,"success");else{o.o=6;try{var A=ce(o)>2?o.g.statusText:""}catch{A=""}o.l=A+" ["+o.ca()+"]",xu(o)}}finally{gs(o)}}}}function gs(o,c){if(o.g){o.m&&(clearTimeout(o.m),o.m=null);const h=o.g;o.g=null,c||St(o,"ready");try{h.onreadystatechange=null}catch{}}}r.isActive=function(){return!!this.g};function ce(o){return o.g?o.g.readyState:0}r.ca=function(){try{return ce(this)>2?this.g.status:-1}catch{return-1}},r.la=function(){try{return this.g?this.g.responseText:""}catch{return""}},r.La=function(o){if(this.g){var c=this.g.responseText;return o&&c.indexOf(o)==0&&(c=c.substring(o.length)),Rf(c)}};function ku(o){try{if(!o.g)return null;if("response"in o.g)return o.g.response;switch(o.F){case"":case"text":return o.g.responseText;case"arraybuffer":if("mozResponseArrayBuffer"in o.g)return o.g.mozResponseArrayBuffer}return null}catch{return null}}function Qf(o){const c={};o=(o.g&&ce(o)>=2&&o.g.getAllResponseHeaders()||"").split(`\r
`);for(let m=0;m<o.length;m++){if(_(o[m]))continue;var h=xf(o[m]);const A=h[0];if(h=h[1],typeof h!="string")continue;h=h.trim();const R=c[A]||[];c[A]=R,R.push(h)}Ef(c,function(m){return m.join(", ")})}r.ya=function(){return this.o},r.Ha=function(){return typeof this.l=="string"?this.l:String(this.l)};function cr(o,c,h){return h&&h.internalChannelParams&&h.internalChannelParams[o]||c}function Mu(o){this.za=0,this.i=[],this.j=new Zn,this.ba=this.na=this.J=this.W=this.g=this.wa=this.G=this.H=this.u=this.U=this.o=null,this.Ya=this.V=0,this.Sa=cr("failFast",!1,o),this.F=this.C=this.v=this.m=this.l=null,this.X=!0,this.xa=this.K=-1,this.Y=this.A=this.D=0,this.Qa=cr("baseRetryDelayMs",5e3,o),this.Za=cr("retryDelaySeedMs",1e4,o),this.Ta=cr("forwardChannelMaxRetries",2,o),this.va=cr("forwardChannelRequestTimeoutMs",2e4,o),this.ma=o&&o.xmlHttpFactory||void 0,this.Ua=o&&o.Rb||void 0,this.Aa=o&&o.useFetchStreams||!1,this.O=void 0,this.L=o&&o.supportsCrossDomainXhr||!1,this.M="",this.h=new _u(o&&o.concurrentRequestLimit),this.Ba=new Gf,this.S=o&&o.fastHandshake||!1,this.R=o&&o.encodeInitMessageHeaders||!1,this.S&&this.R&&(this.R=!1),this.Ra=o&&o.Pb||!1,o&&o.ua&&this.j.ua(),o&&o.forceLongPolling&&(this.X=!1),this.aa=!this.S&&this.X&&o&&o.detectBufferingProxy||!1,this.ia=void 0,o&&o.longPollingTimeout&&o.longPollingTimeout>0&&(this.ia=o.longPollingTimeout),this.ta=void 0,this.T=0,this.P=!1,this.ja=this.B=null}r=Mu.prototype,r.ka=8,r.I=1,r.connect=function(o,c,h,m){Vt(0),this.W=o,this.H=c||{},h&&m!==void 0&&(this.H.OSID=h,this.H.OAID=m),this.F=this.X,this.J=$u(this,null,this.W),_s(this)};function Zi(o){if(Ou(o),o.I==3){var c=o.V++,h=$t(o.J);if(st(h,"SID",o.M),st(h,"RID",c),st(h,"TYPE","terminate"),lr(o,h),c=new oe(o,o.j,c),c.M=2,c.A=fs($t(h)),h=!1,a.navigator&&a.navigator.sendBeacon)try{h=a.navigator.sendBeacon(c.A.toString(),"")}catch{}!h&&a.Image&&(new Image().src=c.A,h=!0),h||(c.g=Gu(c.j,null),c.g.ea(c.A)),c.F=Date.now(),ds(c)}zu(o)}function ps(o){o.g&&(eo(o),o.g.cancel(),o.g=null)}function Ou(o){ps(o),o.v&&(a.clearTimeout(o.v),o.v=null),ys(o),o.h.cancel(),o.m&&(typeof o.m=="number"&&a.clearTimeout(o.m),o.m=null)}function _s(o){if(!yu(o.h)&&!o.m){o.m=!0;var c=o.Ea;W||p(),J||(W(),J=!0),I.add(c,o),o.D=0}}function Wf(o,c){return Iu(o.h)>=o.h.j-(o.m?1:0)?!1:o.m?(o.i=c.G.concat(o.i),!0):o.I==1||o.I==2||o.D>=(o.Sa?0:o.Ta)?!1:(o.m=Xn(d(o.Ea,o,c),ju(o,o.D)),o.D++,!0)}r.Ea=function(o){if(this.m)if(this.m=null,this.I==1){if(!o){this.V=Math.floor(Math.random()*1e5),o=this.V++;const A=new oe(this,this.j,o);let R=this.o;if(this.U&&(R?(R=Qa(R),Ja(R,this.U)):R=this.U),this.u!==null||this.R||(A.J=R,R=null),this.S)t:{for(var c=0,h=0;h<this.i.length;h++){e:{var m=this.i[h];if("__data__"in m.map&&(m=m.map.__data__,typeof m=="string")){m=m.length;break e}m=void 0}if(m===void 0)break;if(c+=m,c>4096){c=h;break t}if(c===4096||h===this.i.length-1){c=h+1;break t}}c=1e3}else c=1e3;c=Lu(this,A,c),h=$t(this.J),st(h,"RID",o),st(h,"CVER",22),this.G&&st(h,"X-HTTP-Session-Id",this.G),lr(this,h),R&&(this.R?c="headers="+tr(Cu(R))+"&"+c:this.u&&Xi(h,this.u,R)),Wi(this.h,A),this.Ra&&st(h,"TYPE","init"),this.S?(st(h,"$req",c),st(h,"SID","null"),A.U=!0,Gi(A,h,null)):Gi(A,h,c),this.I=2}}else this.I==3&&(o?Fu(this,o):this.i.length==0||yu(this.h)||Fu(this))};function Fu(o,c){var h;c?h=c.l:h=o.V++;const m=$t(o.J);st(m,"SID",o.M),st(m,"RID",h),st(m,"AID",o.K),lr(o,m),o.u&&o.o&&Xi(m,o.u,o.o),h=new oe(o,o.j,h,o.D+1),o.u===null&&(h.J=o.o),c&&(o.i=c.G.concat(o.i)),c=Lu(o,h,1e3),h.H=Math.round(o.va*.5)+Math.round(o.va*.5*Math.random()),Wi(o.h,h),Gi(h,m,c)}function lr(o,c){o.H&&as(o.H,function(h,m){st(c,m,h)}),o.l&&as({},function(h,m){st(c,m,h)})}function Lu(o,c,h){h=Math.min(o.i.length,h);const m=o.l?d(o.l.Ka,o.l,o):null;t:{var A=o.i;let z=-1;for(;;){const gt=["count="+h];z==-1?h>0?(z=A[0].g,gt.push("ofs="+z)):z=0:gt.push("ofs="+z);let et=!0;for(let yt=0;yt<h;yt++){var R=A[yt].g;const Gt=A[yt].map;if(R-=z,R<0)z=Math.max(0,A[yt].g-100),et=!1;else try{R="req"+R+"_"||"";try{var x=Gt instanceof Map?Gt:Object.entries(Gt);for(const[Oe,le]of x){let he=le;u(le)&&(he=Ui(le)),gt.push(R+Oe+"="+encodeURIComponent(he))}}catch(Oe){throw gt.push(R+"type="+encodeURIComponent("_badmap")),Oe}}catch{m&&m(Gt)}}if(et){x=gt.join("&");break t}}x=void 0}return o=o.i.splice(0,h),c.G=o,x}function Bu(o){if(!o.g&&!o.v){o.Y=1;var c=o.Da;W||p(),J||(W(),J=!0),I.add(c,o),o.A=0}}function to(o){return o.g||o.v||o.A>=3?!1:(o.Y++,o.v=Xn(d(o.Da,o),ju(o,o.A)),o.A++,!0)}r.Da=function(){if(this.v=null,Uu(this),this.aa&&!(this.P||this.g==null||this.T<=0)){var o=4*this.T;this.j.info("BP detection timer enabled: "+o),this.B=Xn(d(this.Wa,this),o)}},r.Wa=function(){this.B&&(this.B=null,this.j.info("BP detection timeout reached."),this.j.info("Buffering proxy detected and switch to long-polling!"),this.F=!1,this.P=!0,Vt(10),ps(this),Uu(this))};function eo(o){o.B!=null&&(a.clearTimeout(o.B),o.B=null)}function Uu(o){o.g=new oe(o,o.j,"rpc",o.Y),o.u===null&&(o.g.J=o.o),o.g.P=0;var c=$t(o.na);st(c,"RID","rpc"),st(c,"SID",o.M),st(c,"AID",o.K),st(c,"CI",o.F?"0":"1"),!o.F&&o.ia&&st(c,"TO",o.ia),st(c,"TYPE","xmlhttp"),lr(o,c),o.u&&o.o&&Xi(c,o.u,o.o),o.O&&(o.g.H=o.O);var h=o.g;o=o.ba,h.M=1,h.A=fs($t(c)),h.u=null,h.R=!0,mu(h,o)}r.Va=function(){this.C!=null&&(this.C=null,ps(this),to(this),Vt(19))};function ys(o){o.C!=null&&(a.clearTimeout(o.C),o.C=null)}function qu(o,c){var h=null;if(o.g==c){ys(o),eo(o),o.g=null;var m=2}else if(Qi(o.h,c))h=c.G,Eu(o.h,c),m=1;else return;if(o.I!=0){if(c.o)if(m==1){h=c.u?c.u.length:0,c=Date.now()-c.F;var A=o.D;m=ls(),St(m,new cu(m,h)),_s(o)}else Bu(o);else if(A=c.m,A==3||A==0&&c.X>0||!(m==1&&Wf(o,c)||m==2&&to(o)))switch(h&&h.length>0&&(c=o.h,c.i=c.i.concat(h)),A){case 1:Me(o,5);break;case 4:Me(o,10);break;case 3:Me(o,6);break;default:Me(o,2)}}}function ju(o,c){let h=o.Qa+Math.floor(Math.random()*o.Za);return o.isActive()||(h*=2),h*c}function Me(o,c){if(o.j.info("Error code "+c),c==2){var h=d(o.bb,o),m=o.Ua;const A=!m;m=new ae(m||"//www.google.com/images/cleardot.gif"),a.location&&a.location.protocol=="http"||nr(m,"https"),fs(m),A?zf(m.toString(),h):$f(m.toString(),h)}else Vt(2);o.I=0,o.l&&o.l.pa(c),zu(o),Ou(o)}r.bb=function(o){o?(this.j.info("Successfully pinged google.com"),Vt(2)):(this.j.info("Failed to ping google.com"),Vt(1))};function zu(o){if(o.I=0,o.ja=[],o.l){const c=Tu(o.h);(c.length!=0||o.i.length!=0)&&(D(o.ja,c),D(o.ja,o.i),o.h.i.length=0,V(o.i),o.i.length=0),o.l.oa()}}function $u(o,c,h){var m=h instanceof ae?$t(h):new ae(h);if(m.g!="")c&&(m.g=c+"."+m.g),rr(m,m.u);else{var A=a.location;m=A.protocol,c=c?c+"."+A.hostname:A.hostname,A=+A.port;const R=new ae(null);m&&nr(R,m),c&&(R.g=c),A&&rr(R,A),h&&(R.h=h),m=R}return h=o.G,c=o.wa,h&&c&&st(m,h,c),st(m,"VER",o.ka),lr(o,m),m}function Gu(o,c,h){if(c&&!o.L)throw Error("Can't create secondary domain capable XhrIo object.");return c=o.Aa&&!o.ma?new ut(new Yi({ab:h})):new ut(o.ma),c.Fa(o.L),c}r.isActive=function(){return!!this.l&&this.l.isActive(this)};function Ku(){}r=Ku.prototype,r.ra=function(){},r.qa=function(){},r.pa=function(){},r.oa=function(){},r.isActive=function(){return!0},r.Ka=function(){};function Is(){}Is.prototype.g=function(o,c){return new Nt(o,c)};function Nt(o,c){Tt.call(this),this.g=new Mu(c),this.l=o,this.h=c&&c.messageUrlParams||null,o=c&&c.messageHeaders||null,c&&c.clientProtocolHeaderRequired&&(o?o["X-Client-Protocol"]="webchannel":o={"X-Client-Protocol":"webchannel"}),this.g.o=o,o=c&&c.initMessageHeaders||null,c&&c.messageContentType&&(o?o["X-WebChannel-Content-Type"]=c.messageContentType:o={"X-WebChannel-Content-Type":c.messageContentType}),c&&c.sa&&(o?o["X-WebChannel-Client-Profile"]=c.sa:o={"X-WebChannel-Client-Profile":c.sa}),this.g.U=o,(o=c&&c.Qb)&&!_(o)&&(this.g.u=o),this.A=c&&c.supportsCrossDomainXhr||!1,this.v=c&&c.sendRawJson||!1,(c=c&&c.httpSessionIdParam)&&!_(c)&&(this.g.G=c,o=this.h,o!==null&&c in o&&(o=this.h,c in o&&delete o[c])),this.j=new un(this)}g(Nt,Tt),Nt.prototype.m=function(){this.g.l=this.j,this.A&&(this.g.L=!0),this.g.connect(this.l,this.h||void 0)},Nt.prototype.close=function(){Zi(this.g)},Nt.prototype.o=function(o){var c=this.g;if(typeof o=="string"){var h={};h.__data__=o,o=h}else this.v&&(h={},h.__data__=Ui(o),o=h);c.i.push(new Mf(c.Ya++,o)),c.I==3&&_s(c)},Nt.prototype.N=function(){this.g.l=null,delete this.j,Zi(this.g),delete this.g,Nt.Z.N.call(this)};function Hu(o){qi.call(this),o.__headers__&&(this.headers=o.__headers__,this.statusCode=o.__status__,delete o.__headers__,delete o.__status__);var c=o.__sm__;if(c){t:{for(const h in c){o=h;break t}o=void 0}(this.i=o)&&(o=this.i,c=c!==null&&o in c?c[o]:void 0),this.data=c}else this.data=o}g(Hu,qi);function Qu(){ji.call(this),this.status=1}g(Qu,ji);function un(o){this.g=o}g(un,Ku),un.prototype.ra=function(){St(this.g,"a")},un.prototype.qa=function(o){St(this.g,new Hu(o))},un.prototype.pa=function(o){St(this.g,new Qu)},un.prototype.oa=function(){St(this.g,"b")},Is.prototype.createWebChannel=Is.prototype.g,Nt.prototype.send=Nt.prototype.o,Nt.prototype.open=Nt.prototype.m,Nt.prototype.close=Nt.prototype.close,Wl=function(){return new Is},Ql=function(){return ls()},Hl=xe,Ao={jb:0,mb:1,nb:2,Hb:3,Mb:4,Jb:5,Kb:6,Ib:7,Gb:8,Lb:9,PROXY:10,NOPROXY:11,Eb:12,Ab:13,Bb:14,zb:15,Cb:16,Db:17,fb:18,eb:19,gb:20},hs.NO_ERROR=0,hs.TIMEOUT=8,hs.HTTP_ERROR=6,Vs=hs,lu.COMPLETE="complete",Kl=lu,iu.EventType=Jn,Jn.OPEN="a",Jn.CLOSE="b",Jn.ERROR="c",Jn.MESSAGE="d",Tt.prototype.listen=Tt.prototype.J,_r=iu,ut.prototype.listenOnce=ut.prototype.K,ut.prototype.getLastError=ut.prototype.Ha,ut.prototype.getLastErrorCode=ut.prototype.ya,ut.prototype.getStatus=ut.prototype.ca,ut.prototype.getResponseJson=ut.prototype.La,ut.prototype.getResponseText=ut.prototype.la,ut.prototype.send=ut.prototype.ea,ut.prototype.setWithCredentials=ut.prototype.Fa,Gl=ut}).apply(typeof Ts<"u"?Ts:typeof self<"u"?self:typeof window<"u"?window:{});/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class vt{constructor(t){this.uid=t}isAuthenticated(){return this.uid!=null}toKey(){return this.isAuthenticated()?"uid:"+this.uid:"anonymous-user"}isEqual(t){return t.uid===this.uid}}vt.UNAUTHENTICATED=new vt(null),vt.GOOGLE_CREDENTIALS=new vt("google-credentials-uid"),vt.FIRST_PARTY=new vt("first-party-uid"),vt.MOCK_USER=new vt("mock-user");/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let zn="12.11.0";function Ag(r){zn=r}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *//**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Je=new Bl("@firebase/firestore");function gn(){return Je.logLevel}function P(r,...t){if(Je.logLevel<=Q.DEBUG){const e=t.map(Yo);Je.debug(`Firestore (${zn}): ${r}`,...e)}}function lt(r,...t){if(Je.logLevel<=Q.ERROR){const e=t.map(Yo);Je.error(`Firestore (${zn}): ${r}`,...e)}}function vn(r,...t){if(Je.logLevel<=Q.WARN){const e=t.map(Yo);Je.warn(`Firestore (${zn}): ${r}`,...e)}}function Yo(r){if(typeof r=="string")return r;try{return(function(e){return JSON.stringify(e)})(r)}catch{return r}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function O(r,t,e){let n="Unexpected state";typeof t=="string"?n=t:e=t,Jl(r,n,e)}function Jl(r,t,e){let n=`FIRESTORE (${zn}) INTERNAL ASSERTION FAILED: ${t} (ID: ${r.toString(16)})`;if(e!==void 0)try{n+=" CONTEXT: "+JSON.stringify(e)}catch{n+=" CONTEXT: "+e}throw lt(n),new Error(n)}function L(r,t,e,n){let s="Unexpected state";typeof e=="string"?s=e:n=e,r||Jl(t,s,n)}function F(r,t){return r}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const S={OK:"ok",CANCELLED:"cancelled",UNKNOWN:"unknown",INVALID_ARGUMENT:"invalid-argument",DEADLINE_EXCEEDED:"deadline-exceeded",NOT_FOUND:"not-found",ALREADY_EXISTS:"already-exists",PERMISSION_DENIED:"permission-denied",UNAUTHENTICATED:"unauthenticated",RESOURCE_EXHAUSTED:"resource-exhausted",FAILED_PRECONDITION:"failed-precondition",ABORTED:"aborted",OUT_OF_RANGE:"out-of-range",UNIMPLEMENTED:"unimplemented",INTERNAL:"internal",UNAVAILABLE:"unavailable",DATA_LOSS:"data-loss"};class C extends jn{constructor(t,e){super(t,e),this.code=t,this.message=e,this.toString=()=>`${this.name}: [code=${this.code}]: ${this.message}`}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class jt{constructor(){this.promise=new Promise(((t,e)=>{this.resolve=t,this.reject=e}))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class bg{constructor(t,e){this.user=e,this.type="OAuth",this.headers=new Map,this.headers.set("Authorization",`Bearer ${t}`)}}class Rg{getToken(){return Promise.resolve(null)}invalidateToken(){}start(t,e){t.enqueueRetryable((()=>e(vt.UNAUTHENTICATED)))}shutdown(){}}class Sg{constructor(t){this.t=t,this.currentUser=vt.UNAUTHENTICATED,this.i=0,this.forceRefresh=!1,this.auth=null}start(t,e){L(this.o===void 0,42304);let n=this.i;const s=l=>this.i!==n?(n=this.i,e(l)):Promise.resolve();let i=new jt;this.o=()=>{this.i++,this.currentUser=this.u(),i.resolve(),i=new jt,t.enqueueRetryable((()=>s(this.currentUser)))};const a=()=>{const l=i;t.enqueueRetryable((async()=>{await l.promise,await s(this.currentUser)}))},u=l=>{P("FirebaseAuthCredentialsProvider","Auth detected"),this.auth=l,this.o&&(this.auth.addAuthTokenListener(this.o),a())};this.t.onInit((l=>u(l))),setTimeout((()=>{if(!this.auth){const l=this.t.getImmediate({optional:!0});l?u(l):(P("FirebaseAuthCredentialsProvider","Auth not yet detected"),i.resolve(),i=new jt)}}),0),a()}getToken(){const t=this.i,e=this.forceRefresh;return this.forceRefresh=!1,this.auth?this.auth.getToken(e).then((n=>this.i!==t?(P("FirebaseAuthCredentialsProvider","getToken aborted due to token change."),this.getToken()):n?(L(typeof n.accessToken=="string",31837,{l:n}),new bg(n.accessToken,this.currentUser)):null)):Promise.resolve(null)}invalidateToken(){this.forceRefresh=!0}shutdown(){this.auth&&this.o&&this.auth.removeAuthTokenListener(this.o),this.o=void 0}u(){const t=this.auth&&this.auth.getUid();return L(t===null||typeof t=="string",2055,{h:t}),new vt(t)}}class Vg{constructor(t,e,n){this.P=t,this.T=e,this.I=n,this.type="FirstParty",this.user=vt.FIRST_PARTY,this.R=new Map}A(){return this.I?this.I():null}get headers(){this.R.set("X-Goog-AuthUser",this.P);const t=this.A();return t&&this.R.set("Authorization",t),this.T&&this.R.set("X-Goog-Iam-Authorization-Token",this.T),this.R}}class Pg{constructor(t,e,n){this.P=t,this.T=e,this.I=n}getToken(){return Promise.resolve(new Vg(this.P,this.T,this.I))}start(t,e){t.enqueueRetryable((()=>e(vt.FIRST_PARTY)))}shutdown(){}invalidateToken(){}}class oc{constructor(t){this.value=t,this.type="AppCheck",this.headers=new Map,t&&t.length>0&&this.headers.set("x-firebase-appcheck",this.value)}}class Cg{constructor(t,e){this.V=e,this.forceRefresh=!1,this.appCheck=null,this.m=null,this.p=null,cg(t)&&t.settings.appCheckToken&&(this.p=t.settings.appCheckToken)}start(t,e){L(this.o===void 0,3512);const n=i=>{i.error!=null&&P("FirebaseAppCheckTokenProvider",`Error getting App Check token; using placeholder token instead. Error: ${i.error.message}`);const a=i.token!==this.m;return this.m=i.token,P("FirebaseAppCheckTokenProvider",`Received ${a?"new":"existing"} token.`),a?e(i.token):Promise.resolve()};this.o=i=>{t.enqueueRetryable((()=>n(i)))};const s=i=>{P("FirebaseAppCheckTokenProvider","AppCheck detected"),this.appCheck=i,this.o&&this.appCheck.addTokenListener(this.o)};this.V.onInit((i=>s(i))),setTimeout((()=>{if(!this.appCheck){const i=this.V.getImmediate({optional:!0});i?s(i):P("FirebaseAppCheckTokenProvider","AppCheck not yet detected")}}),0)}getToken(){if(this.p)return Promise.resolve(new oc(this.p));const t=this.forceRefresh;return this.forceRefresh=!1,this.appCheck?this.appCheck.getToken(t).then((e=>e?(L(typeof e.token=="string",44558,{tokenResult:e}),this.m=e.token,new oc(e.token)):null)):Promise.resolve(null)}invalidateToken(){this.forceRefresh=!0}shutdown(){this.appCheck&&this.o&&this.appCheck.removeTokenListener(this.o),this.o=void 0}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Dg(r){const t=typeof self<"u"&&(self.crypto||self.msCrypto),e=new Uint8Array(r);if(t&&typeof t.getRandomValues=="function")t.getRandomValues(e);else for(let n=0;n<r;n++)e[n]=Math.floor(256*Math.random());return e}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Xo{static newId(){const t="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e=62*Math.floor(4.129032258064516);let n="";for(;n.length<20;){const s=Dg(40);for(let i=0;i<s.length;++i)n.length<20&&s[i]<e&&(n+=t.charAt(s[i]%62))}return n}}function U(r,t){return r<t?-1:r>t?1:0}function bo(r,t){const e=Math.min(r.length,t.length);for(let n=0;n<e;n++){const s=r.charAt(n),i=t.charAt(n);if(s!==i)return uo(s)===uo(i)?U(s,i):uo(s)?1:-1}return U(r.length,t.length)}const xg=55296,Ng=57343;function uo(r){const t=r.charCodeAt(0);return t>=xg&&t<=Ng}function An(r,t,e){return r.length===t.length&&r.every(((n,s)=>e(n,t[s])))}function Yl(r){return r+"\0"}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const ac="__name__";class Kt{constructor(t,e,n){e===void 0?e=0:e>t.length&&O(637,{offset:e,range:t.length}),n===void 0?n=t.length-e:n>t.length-e&&O(1746,{length:n,range:t.length-e}),this.segments=t,this.offset=e,this.len=n}get length(){return this.len}isEqual(t){return Kt.comparator(this,t)===0}child(t){const e=this.segments.slice(this.offset,this.limit());return t instanceof Kt?t.forEach((n=>{e.push(n)})):e.push(t),this.construct(e)}limit(){return this.offset+this.length}popFirst(t){return t=t===void 0?1:t,this.construct(this.segments,this.offset+t,this.length-t)}popLast(){return this.construct(this.segments,this.offset,this.length-1)}firstSegment(){return this.segments[this.offset]}lastSegment(){return this.get(this.length-1)}get(t){return this.segments[this.offset+t]}isEmpty(){return this.length===0}isPrefixOf(t){if(t.length<this.length)return!1;for(let e=0;e<this.length;e++)if(this.get(e)!==t.get(e))return!1;return!0}isImmediateParentOf(t){if(this.length+1!==t.length)return!1;for(let e=0;e<this.length;e++)if(this.get(e)!==t.get(e))return!1;return!0}forEach(t){for(let e=this.offset,n=this.limit();e<n;e++)t(this.segments[e])}toArray(){return this.segments.slice(this.offset,this.limit())}static comparator(t,e){const n=Math.min(t.length,e.length);for(let s=0;s<n;s++){const i=Kt.compareSegments(t.get(s),e.get(s));if(i!==0)return i}return U(t.length,e.length)}static compareSegments(t,e){const n=Kt.isNumericId(t),s=Kt.isNumericId(e);return n&&!s?-1:!n&&s?1:n&&s?Kt.extractNumericId(t).compare(Kt.extractNumericId(e)):bo(t,e)}static isNumericId(t){return t.startsWith("__id")&&t.endsWith("__")}static extractNumericId(t){return Ie.fromString(t.substring(4,t.length-2))}}class Y extends Kt{construct(t,e,n){return new Y(t,e,n)}canonicalString(){return this.toArray().join("/")}toString(){return this.canonicalString()}toUriEncodedString(){return this.toArray().map(encodeURIComponent).join("/")}static fromString(...t){const e=[];for(const n of t){if(n.indexOf("//")>=0)throw new C(S.INVALID_ARGUMENT,`Invalid segment (${n}). Paths must not contain // in them.`);e.push(...n.split("/").filter((s=>s.length>0)))}return new Y(e)}static emptyPath(){return new Y([])}}const kg=/^[_a-zA-Z][_a-zA-Z0-9]*$/;class ot extends Kt{construct(t,e,n){return new ot(t,e,n)}static isValidIdentifier(t){return kg.test(t)}canonicalString(){return this.toArray().map((t=>(t=t.replace(/\\/g,"\\\\").replace(/`/g,"\\`"),ot.isValidIdentifier(t)||(t="`"+t+"`"),t))).join(".")}toString(){return this.canonicalString()}isKeyField(){return this.length===1&&this.get(0)===ac}static keyField(){return new ot([ac])}static fromServerFormat(t){const e=[];let n="",s=0;const i=()=>{if(n.length===0)throw new C(S.INVALID_ARGUMENT,`Invalid field path (${t}). Paths must not be empty, begin with '.', end with '.', or contain '..'`);e.push(n),n=""};let a=!1;for(;s<t.length;){const u=t[s];if(u==="\\"){if(s+1===t.length)throw new C(S.INVALID_ARGUMENT,"Path has trailing escape character: "+t);const l=t[s+1];if(l!=="\\"&&l!=="."&&l!=="`")throw new C(S.INVALID_ARGUMENT,"Path has invalid escape sequence: "+t);n+=l,s+=2}else u==="`"?(a=!a,s++):u!=="."||a?(n+=u,s++):(i(),s++)}if(i(),a)throw new C(S.INVALID_ARGUMENT,"Unterminated ` in path: "+t);return new ot(e)}static emptyPath(){return new ot([])}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class N{constructor(t){this.path=t}static fromPath(t){return new N(Y.fromString(t))}static fromName(t){return new N(Y.fromString(t).popFirst(5))}static empty(){return new N(Y.emptyPath())}get collectionGroup(){return this.path.popLast().lastSegment()}hasCollectionId(t){return this.path.length>=2&&this.path.get(this.path.length-2)===t}getCollectionGroup(){return this.path.get(this.path.length-2)}getCollectionPath(){return this.path.popLast()}isEqual(t){return t!==null&&Y.comparator(this.path,t.path)===0}toString(){return this.path.toString()}static comparator(t,e){return Y.comparator(t.path,e.path)}static isDocumentKey(t){return t.length%2==0}static fromSegments(t){return new N(new Y(t.slice()))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Xl(r,t,e){if(!e)throw new C(S.INVALID_ARGUMENT,`Function ${r}() cannot be called with an empty ${t}.`)}function Mg(r,t,e,n){if(t===!0&&n===!0)throw new C(S.INVALID_ARGUMENT,`${r} and ${e} cannot be used together.`)}function uc(r){if(!N.isDocumentKey(r))throw new C(S.INVALID_ARGUMENT,`Invalid document reference. Document references must have an even number of segments, but ${r} has ${r.length}.`)}function cc(r){if(N.isDocumentKey(r))throw new C(S.INVALID_ARGUMENT,`Invalid collection reference. Collection references must have an odd number of segments, but ${r} has ${r.length}.`)}function Zl(r){return typeof r=="object"&&r!==null&&(Object.getPrototypeOf(r)===Object.prototype||Object.getPrototypeOf(r)===null)}function li(r){if(r===void 0)return"undefined";if(r===null)return"null";if(typeof r=="string")return r.length>20&&(r=`${r.substring(0,20)}...`),JSON.stringify(r);if(typeof r=="number"||typeof r=="boolean")return""+r;if(typeof r=="object"){if(r instanceof Array)return"an array";{const t=(function(n){return n.constructor?n.constructor.name:null})(r);return t?`a custom ${t} object`:"an object"}}return typeof r=="function"?"a function":O(12329,{type:typeof r})}function mt(r,t){if("_delegate"in r&&(r=r._delegate),!(r instanceof t)){if(t.name===r.constructor.name)throw new C(S.INVALID_ARGUMENT,"Type does not match the expected instance. Did you pass a reference from a different Firestore SDK?");{const e=li(r);throw new C(S.INVALID_ARGUMENT,`Expected type '${t.name}', but it was: ${e}`)}}return r}/**
 * @license
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function ft(r,t){const e={typeString:r};return t&&(e.value=t),e}function Hr(r,t){if(!Zl(r))throw new C(S.INVALID_ARGUMENT,"JSON must be an object");let e;for(const n in t)if(t[n]){const s=t[n].typeString,i="value"in t[n]?{value:t[n].value}:void 0;if(!(n in r)){e=`JSON missing required field: '${n}'`;break}const a=r[n];if(s&&typeof a!==s){e=`JSON field '${n}' must be a ${s}.`;break}if(i!==void 0&&a!==i.value){e=`Expected '${n}' field to equal '${i.value}'`;break}}if(e)throw new C(S.INVALID_ARGUMENT,e);return!0}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const lc=-62135596800,hc=1e6;class X{static now(){return X.fromMillis(Date.now())}static fromDate(t){return X.fromMillis(t.getTime())}static fromMillis(t){const e=Math.floor(t/1e3),n=Math.floor((t-1e3*e)*hc);return new X(e,n)}constructor(t,e){if(this.seconds=t,this.nanoseconds=e,e<0)throw new C(S.INVALID_ARGUMENT,"Timestamp nanoseconds out of range: "+e);if(e>=1e9)throw new C(S.INVALID_ARGUMENT,"Timestamp nanoseconds out of range: "+e);if(t<lc)throw new C(S.INVALID_ARGUMENT,"Timestamp seconds out of range: "+t);if(t>=253402300800)throw new C(S.INVALID_ARGUMENT,"Timestamp seconds out of range: "+t)}toDate(){return new Date(this.toMillis())}toMillis(){return 1e3*this.seconds+this.nanoseconds/hc}_compareTo(t){return this.seconds===t.seconds?U(this.nanoseconds,t.nanoseconds):U(this.seconds,t.seconds)}isEqual(t){return t.seconds===this.seconds&&t.nanoseconds===this.nanoseconds}toString(){return"Timestamp(seconds="+this.seconds+", nanoseconds="+this.nanoseconds+")"}toJSON(){return{type:X._jsonSchemaVersion,seconds:this.seconds,nanoseconds:this.nanoseconds}}static fromJSON(t){if(Hr(t,X._jsonSchema))return new X(t.seconds,t.nanoseconds)}valueOf(){const t=this.seconds-lc;return String(t).padStart(12,"0")+"."+String(this.nanoseconds).padStart(9,"0")}}X._jsonSchemaVersion="firestore/timestamp/1.0",X._jsonSchema={type:ft("string",X._jsonSchemaVersion),seconds:ft("number"),nanoseconds:ft("number")};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class B{static fromTimestamp(t){return new B(t)}static min(){return new B(new X(0,0))}static max(){return new B(new X(253402300799,999999999))}constructor(t){this.timestamp=t}compareTo(t){return this.timestamp._compareTo(t.timestamp)}isEqual(t){return this.timestamp.isEqual(t.timestamp)}toMicroseconds(){return 1e6*this.timestamp.seconds+this.timestamp.nanoseconds/1e3}toString(){return"SnapshotVersion("+this.timestamp.toString()+")"}toTimestamp(){return this.timestamp}}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const bn=-1;class zs{constructor(t,e,n,s){this.indexId=t,this.collectionGroup=e,this.fields=n,this.indexState=s}}function Ro(r){return r.fields.find((t=>t.kind===2))}function Be(r){return r.fields.filter((t=>t.kind!==2))}zs.UNKNOWN_ID=-1;class Ps{constructor(t,e){this.fieldPath=t,this.kind=e}}class kr{constructor(t,e){this.sequenceNumber=t,this.offset=e}static empty(){return new kr(0,Ft.min())}}function th(r,t){const e=r.toTimestamp().seconds,n=r.toTimestamp().nanoseconds+1,s=B.fromTimestamp(n===1e9?new X(e+1,0):new X(e,n));return new Ft(s,N.empty(),t)}function eh(r){return new Ft(r.readTime,r.key,bn)}class Ft{constructor(t,e,n){this.readTime=t,this.documentKey=e,this.largestBatchId=n}static min(){return new Ft(B.min(),N.empty(),bn)}static max(){return new Ft(B.max(),N.empty(),bn)}}function Zo(r,t){let e=r.readTime.compareTo(t.readTime);return e!==0?e:(e=N.comparator(r.documentKey,t.documentKey),e!==0?e:U(r.largestBatchId,t.largestBatchId))}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const nh="The current tab is not in the required state to perform this operation. It might be necessary to refresh the browser tab.";class rh{constructor(){this.onCommittedListeners=[]}addOnCommittedListener(t){this.onCommittedListeners.push(t)}raiseOnCommittedEvent(){this.onCommittedListeners.forEach((t=>t()))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function Re(r){if(r.code!==S.FAILED_PRECONDITION||r.message!==nh)throw r;P("LocalStore","Unexpectedly lost primary lease")}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class v{constructor(t){this.nextCallback=null,this.catchCallback=null,this.result=void 0,this.error=void 0,this.isDone=!1,this.callbackAttached=!1,t((e=>{this.isDone=!0,this.result=e,this.nextCallback&&this.nextCallback(e)}),(e=>{this.isDone=!0,this.error=e,this.catchCallback&&this.catchCallback(e)}))}catch(t){return this.next(void 0,t)}next(t,e){return this.callbackAttached&&O(59440),this.callbackAttached=!0,this.isDone?this.error?this.wrapFailure(e,this.error):this.wrapSuccess(t,this.result):new v(((n,s)=>{this.nextCallback=i=>{this.wrapSuccess(t,i).next(n,s)},this.catchCallback=i=>{this.wrapFailure(e,i).next(n,s)}}))}toPromise(){return new Promise(((t,e)=>{this.next(t,e)}))}wrapUserFunction(t){try{const e=t();return e instanceof v?e:v.resolve(e)}catch(e){return v.reject(e)}}wrapSuccess(t,e){return t?this.wrapUserFunction((()=>t(e))):v.resolve(e)}wrapFailure(t,e){return t?this.wrapUserFunction((()=>t(e))):v.reject(e)}static resolve(t){return new v(((e,n)=>{e(t)}))}static reject(t){return new v(((e,n)=>{n(t)}))}static waitFor(t){return new v(((e,n)=>{let s=0,i=0,a=!1;t.forEach((u=>{++s,u.next((()=>{++i,a&&i===s&&e()}),(l=>n(l)))})),a=!0,i===s&&e()}))}static or(t){let e=v.resolve(!1);for(const n of t)e=e.next((s=>s?v.resolve(s):n()));return e}static forEach(t,e){const n=[];return t.forEach(((s,i)=>{n.push(e.call(this,s,i))})),this.waitFor(n)}static mapArray(t,e){return new v(((n,s)=>{const i=t.length,a=new Array(i);let u=0;for(let l=0;l<i;l++){const d=l;e(t[d]).next((f=>{a[d]=f,++u,u===i&&n(a)}),(f=>s(f)))}}))}static doWhile(t,e){return new v(((n,s)=>{const i=()=>{t()===!0?e().next((()=>{i()}),s):n()};i()}))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const kt="SimpleDb";class hi{static open(t,e,n,s){try{return new hi(e,t.transaction(s,n))}catch(i){throw new vr(e,i)}}constructor(t,e){this.action=t,this.transaction=e,this.aborted=!1,this.S=new jt,this.transaction.oncomplete=()=>{this.S.resolve()},this.transaction.onabort=()=>{e.error?this.S.reject(new vr(t,e.error)):this.S.resolve()},this.transaction.onerror=n=>{const s=ta(n.target.error);this.S.reject(new vr(t,s))}}get D(){return this.S.promise}abort(t){t&&this.S.reject(t),this.aborted||(P(kt,"Aborting transaction:",t?t.message:"Client-initiated abort"),this.aborted=!0,this.transaction.abort())}C(){const t=this.transaction;this.aborted||typeof t.commit!="function"||t.commit()}store(t){const e=this.transaction.objectStore(t);return new Fg(e)}}class Ee{static delete(t){return P(kt,"Removing database:",t),qe(Dl().indexedDB.deleteDatabase(t)).toPromise()}static v(){if(!Ol())return!1;if(Ee.F())return!0;const t=wn(),e=Ee.M(t),n=0<e&&e<10,s=sh(t),i=0<s&&s<4.5;return!(t.indexOf("MSIE ")>0||t.indexOf("Trident/")>0||t.indexOf("Edge/")>0||n||i)}static F(){var t;return typeof process<"u"&&((t=process.__PRIVATE_env)==null?void 0:t.__PRIVATE_USE_MOCK_PERSISTENCE)==="YES"}static O(t,e){return t.store(e)}static M(t){const e=t.match(/i(?:phone|pad|pod) os ([\d_]+)/i),n=e?e[1].split("_").slice(0,2).join("."):"-1";return Number(n)}constructor(t,e,n){this.name=t,this.version=e,this.N=n,this.B=null,Ee.M(wn())===12.2&&lt("Firestore persistence suffers from a bug in iOS 12.2 Safari that may cause your app to stop working. See https://stackoverflow.com/q/56496296/110915 for details and a potential workaround.")}async L(t){return this.db||(P(kt,"Opening database:",this.name),this.db=await new Promise(((e,n)=>{const s=indexedDB.open(this.name,this.version);s.onsuccess=i=>{const a=i.target.result;e(a)},s.onblocked=()=>{n(new vr(t,"Cannot upgrade IndexedDB schema while another tab is open. Close all tabs that access Firestore and reload this page to proceed."))},s.onerror=i=>{const a=i.target.error;a.name==="VersionError"?n(new C(S.FAILED_PRECONDITION,"A newer version of the Firestore SDK was previously used and so the persisted data is not compatible with the version of the SDK you are now using. The SDK will operate with persistence disabled. If you need persistence, please re-upgrade to a newer version of the SDK or else clear the persisted IndexedDB data for your app to start fresh.")):a.name==="InvalidStateError"?n(new C(S.FAILED_PRECONDITION,"Unable to open an IndexedDB connection. This could be due to running in a private browsing session on a browser whose private browsing sessions do not support IndexedDB: "+a)):n(new vr(t,a))},s.onupgradeneeded=i=>{P(kt,'Database "'+this.name+'" requires upgrade from version:',i.oldVersion);const a=i.target.result;this.N.k(a,s.transaction,i.oldVersion,this.version).next((()=>{P(kt,"Database upgrade to version "+this.version+" complete")}))}}))),this.q&&(this.db.onversionchange=e=>this.q(e)),this.db}K(t){this.q=t,this.db&&(this.db.onversionchange=e=>t(e))}async runTransaction(t,e,n,s){const i=e==="readonly";let a=0;for(;;){++a;try{this.db=await this.L(t);const u=hi.open(this.db,t,i?"readonly":"readwrite",n),l=s(u).next((d=>(u.C(),d))).catch((d=>(u.abort(d),v.reject(d)))).toPromise();return l.catch((()=>{})),await u.D,l}catch(u){const l=u,d=l.name!=="FirebaseError"&&a<3;if(P(kt,"Transaction failed with error:",l.message,"Retrying:",d),this.close(),!d)return Promise.reject(l)}}}close(){this.db&&this.db.close(),this.db=void 0}}function sh(r){const t=r.match(/Android ([\d.]+)/i),e=t?t[1].split(".").slice(0,2).join("."):"-1";return Number(e)}class Og{constructor(t){this.U=t,this.$=!1,this.W=null}get isDone(){return this.$}get G(){return this.W}set cursor(t){this.U=t}done(){this.$=!0}j(t){this.W=t}delete(){return qe(this.U.delete())}}class vr extends C{constructor(t,e){super(S.UNAVAILABLE,`IndexedDB transaction '${t}' failed: ${e}`),this.name="IndexedDbTransactionError"}}function Se(r){return r.name==="IndexedDbTransactionError"}class Fg{constructor(t){this.store=t}put(t,e){let n;return e!==void 0?(P(kt,"PUT",this.store.name,t,e),n=this.store.put(e,t)):(P(kt,"PUT",this.store.name,"<auto-key>",t),n=this.store.put(t)),qe(n)}add(t){return P(kt,"ADD",this.store.name,t,t),qe(this.store.add(t))}get(t){return qe(this.store.get(t)).next((e=>(e===void 0&&(e=null),P(kt,"GET",this.store.name,t,e),e)))}delete(t){return P(kt,"DELETE",this.store.name,t),qe(this.store.delete(t))}count(){return P(kt,"COUNT",this.store.name),qe(this.store.count())}J(t,e){const n=this.options(t,e),s=n.index?this.store.index(n.index):this.store;if(typeof s.getAll=="function"){const i=s.getAll(n.range);return new v(((a,u)=>{i.onerror=l=>{u(l.target.error)},i.onsuccess=l=>{a(l.target.result)}}))}{const i=this.cursor(n),a=[];return this.H(i,((u,l)=>{a.push(l)})).next((()=>a))}}Z(t,e){const n=this.store.getAll(t,e===null?void 0:e);return new v(((s,i)=>{n.onerror=a=>{i(a.target.error)},n.onsuccess=a=>{s(a.target.result)}}))}X(t,e){P(kt,"DELETE ALL",this.store.name);const n=this.options(t,e);n.Y=!1;const s=this.cursor(n);return this.H(s,((i,a,u)=>u.delete()))}ee(t,e){let n;e?n=t:(n={},e=t);const s=this.cursor(n);return this.H(s,e)}te(t){const e=this.cursor({});return new v(((n,s)=>{e.onerror=i=>{const a=ta(i.target.error);s(a)},e.onsuccess=i=>{const a=i.target.result;a?t(a.primaryKey,a.value).next((u=>{u?a.continue():n()})):n()}}))}H(t,e){const n=[];return new v(((s,i)=>{t.onerror=a=>{i(a.target.error)},t.onsuccess=a=>{const u=a.target.result;if(!u)return void s();const l=new Og(u),d=e(u.primaryKey,u.value,l);if(d instanceof v){const f=d.catch((g=>(l.done(),v.reject(g))));n.push(f)}l.isDone?s():l.G===null?u.continue():u.continue(l.G)}})).next((()=>v.waitFor(n)))}options(t,e){let n;return t!==void 0&&(typeof t=="string"?n=t:e=t),{index:n,range:e}}cursor(t){let e="next";if(t.reverse&&(e="prev"),t.index){const n=this.store.index(t.index);return t.Y?n.openKeyCursor(t.range,e):n.openCursor(t.range,e)}return this.store.openCursor(t.range,e)}}function qe(r){return new v(((t,e)=>{r.onsuccess=n=>{const s=n.target.result;t(s)},r.onerror=n=>{const s=ta(n.target.error);e(s)}}))}let dc=!1;function ta(r){const t=Ee.M(wn());if(t>=12.2&&t<13){const e="An internal error was encountered in the Indexed Database server";if(r.message.indexOf(e)>=0){const n=new C("internal",`IOS_INDEXEDDB_BUG1: IndexedDb has thrown '${e}'. This is likely due to an unavoidable bug in iOS. See https://stackoverflow.com/q/56496296/110915 for details and a potential workaround.`);return dc||(dc=!0,setTimeout((()=>{throw n}),0)),n}}return r}const Ar="IndexBackfiller";class Lg{constructor(t,e){this.asyncQueue=t,this.ne=e,this.task=null}start(){this.re(15e3)}stop(){this.task&&(this.task.cancel(),this.task=null)}get started(){return this.task!==null}re(t){P(Ar,`Scheduled in ${t}ms`),this.task=this.asyncQueue.enqueueAfterDelay("index_backfill",t,(async()=>{this.task=null;try{const e=await this.ne.ie();P(Ar,`Documents written: ${e}`)}catch(e){Se(e)?P(Ar,"Ignoring IndexedDB error during index backfill: ",e):await Re(e)}await this.re(6e4)}))}}class Bg{constructor(t,e){this.localStore=t,this.persistence=e}async ie(t=50){return this.persistence.runTransaction("Backfill Indexes","readwrite-primary",(e=>this.se(e,t)))}se(t,e){const n=new Set;let s=e,i=!0;return v.doWhile((()=>i===!0&&s>0),(()=>this.localStore.indexManager.getNextCollectionGroupToUpdate(t).next((a=>{if(a!==null&&!n.has(a))return P(Ar,`Processing collection: ${a}`),this.oe(t,a,s).next((u=>{s-=u,n.add(a)}));i=!1})))).next((()=>e-s))}oe(t,e,n){return this.localStore.indexManager.getMinOffsetFromCollectionGroup(t,e).next((s=>this.localStore.localDocuments.getNextDocuments(t,e,s,n).next((i=>{const a=i.changes;return this.localStore.indexManager.updateIndexEntries(t,a).next((()=>this._e(s,i))).next((u=>(P(Ar,`Updating offset: ${u}`),this.localStore.indexManager.updateCollectionGroup(t,e,u)))).next((()=>a.size))}))))}_e(t,e){let n=t;return e.changes.forEach(((s,i)=>{const a=eh(i);Zo(a,n)>0&&(n=a)})),new Ft(n.readTime,n.documentKey,Math.max(e.batchId,t.largestBatchId))}}/**
 * @license
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Dt{constructor(t,e){this.previousValue=t,e&&(e.sequenceNumberHandler=n=>this.ae(n),this.ue=n=>e.writeSequenceNumber(n))}ae(t){return this.previousValue=Math.max(t,this.previousValue),this.previousValue}next(){const t=++this.previousValue;return this.ue&&this.ue(t),t}}Dt.ce=-1;/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Ke=-1;function di(r){return r==null}function Mr(r){return r===0&&1/r==-1/0}function ih(r){return typeof r=="number"&&Number.isInteger(r)&&!Mr(r)&&r<=Number.MAX_SAFE_INTEGER&&r>=Number.MIN_SAFE_INTEGER}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const $s="";function Rt(r){let t="";for(let e=0;e<r.length;e++)t.length>0&&(t=fc(t)),t=Ug(r.get(e),t);return fc(t)}function Ug(r,t){let e=t;const n=r.length;for(let s=0;s<n;s++){const i=r.charAt(s);switch(i){case"\0":e+="";break;case $s:e+="";break;default:e+=i}}return e}function fc(r){return r+$s+""}function Qt(r){const t=r.length;if(L(t>=2,64408,{path:r}),t===2)return L(r.charAt(0)===$s&&r.charAt(1)==="",56145,{path:r}),Y.emptyPath();const e=t-2,n=[];let s="";for(let i=0;i<t;){const a=r.indexOf($s,i);switch((a<0||a>e)&&O(50515,{path:r}),r.charAt(a+1)){case"":const u=r.substring(i,a);let l;s.length===0?l=u:(s+=u,l=s,s=""),n.push(l);break;case"":s+=r.substring(i,a),s+="\0";break;case"":s+=r.substring(i,a+1);break;default:O(61167,{path:r})}i=a+2}return new Y(n)}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Ue="remoteDocuments",Qr="owner",cn="owner",Or="mutationQueues",qg="userId",qt="mutations",mc="batchId",Ge="userMutationsIndex",gc=["userId","batchId"];/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Cs(r,t){return[r,Rt(t)]}function oh(r,t,e){return[r,Rt(t),e]}const jg={},Rn="documentMutations",Gs="remoteDocumentsV14",zg=["prefixPath","collectionGroup","readTime","documentId"],Ds="documentKeyIndex",$g=["prefixPath","collectionGroup","documentId"],ah="collectionGroupIndex",Gg=["collectionGroup","readTime","prefixPath","documentId"],Fr="remoteDocumentGlobal",So="remoteDocumentGlobalKey",Sn="targets",uh="queryTargetsIndex",Kg=["canonicalId","targetId"],Vn="targetDocuments",Hg=["targetId","path"],ea="documentTargetsIndex",Qg=["path","targetId"],Ks="targetGlobalKey",He="targetGlobal",Lr="collectionParents",Wg=["collectionId","parent"],Pn="clientMetadata",Jg="clientId",fi="bundles",Yg="bundleId",mi="namedQueries",Xg="name",na="indexConfiguration",Zg="indexId",Vo="collectionGroupIndex",tp="collectionGroup",br="indexState",ep=["indexId","uid"],ch="sequenceNumberIndex",np=["uid","sequenceNumber"],Rr="indexEntries",rp=["indexId","uid","arrayValue","directionalValue","orderedDocumentKey","documentKey"],lh="documentKeyIndex",sp=["indexId","uid","orderedDocumentKey"],gi="documentOverlays",ip=["userId","collectionPath","documentId"],Po="collectionPathOverlayIndex",op=["userId","collectionPath","largestBatchId"],hh="collectionGroupOverlayIndex",ap=["userId","collectionGroup","largestBatchId"],ra="globals",up="name",dh=[Or,qt,Rn,Ue,Sn,Qr,He,Vn,Pn,Fr,Lr,fi,mi],cp=[...dh,gi],fh=[Or,qt,Rn,Gs,Sn,Qr,He,Vn,Pn,Fr,Lr,fi,mi,gi],mh=fh,sa=[...mh,na,br,Rr],lp=sa,gh=[...sa,ra],hp=gh;/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Co extends rh{constructor(t,e){super(),this.le=t,this.currentSequenceNumber=e}}function _t(r,t){const e=F(r);return Ee.O(e.le,t)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function pc(r){let t=0;for(const e in r)Object.prototype.hasOwnProperty.call(r,e)&&t++;return t}function Ve(r,t){for(const e in r)Object.prototype.hasOwnProperty.call(r,e)&&t(e,r[e])}function ph(r){for(const t in r)if(Object.prototype.hasOwnProperty.call(r,t))return!1;return!0}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class nt{constructor(t,e){this.comparator=t,this.root=e||Et.EMPTY}insert(t,e){return new nt(this.comparator,this.root.insert(t,e,this.comparator).copy(null,null,Et.BLACK,null,null))}remove(t){return new nt(this.comparator,this.root.remove(t,this.comparator).copy(null,null,Et.BLACK,null,null))}get(t){let e=this.root;for(;!e.isEmpty();){const n=this.comparator(t,e.key);if(n===0)return e.value;n<0?e=e.left:n>0&&(e=e.right)}return null}indexOf(t){let e=0,n=this.root;for(;!n.isEmpty();){const s=this.comparator(t,n.key);if(s===0)return e+n.left.size;s<0?n=n.left:(e+=n.left.size+1,n=n.right)}return-1}isEmpty(){return this.root.isEmpty()}get size(){return this.root.size}minKey(){return this.root.minKey()}maxKey(){return this.root.maxKey()}inorderTraversal(t){return this.root.inorderTraversal(t)}forEach(t){this.inorderTraversal(((e,n)=>(t(e,n),!1)))}toString(){const t=[];return this.inorderTraversal(((e,n)=>(t.push(`${e}:${n}`),!1))),`{${t.join(", ")}}`}reverseTraversal(t){return this.root.reverseTraversal(t)}getIterator(){return new ws(this.root,null,this.comparator,!1)}getIteratorFrom(t){return new ws(this.root,t,this.comparator,!1)}getReverseIterator(){return new ws(this.root,null,this.comparator,!0)}getReverseIteratorFrom(t){return new ws(this.root,t,this.comparator,!0)}}class ws{constructor(t,e,n,s){this.isReverse=s,this.nodeStack=[];let i=1;for(;!t.isEmpty();)if(i=e?n(t.key,e):1,e&&s&&(i*=-1),i<0)t=this.isReverse?t.left:t.right;else{if(i===0){this.nodeStack.push(t);break}this.nodeStack.push(t),t=this.isReverse?t.right:t.left}}getNext(){let t=this.nodeStack.pop();const e={key:t.key,value:t.value};if(this.isReverse)for(t=t.left;!t.isEmpty();)this.nodeStack.push(t),t=t.right;else for(t=t.right;!t.isEmpty();)this.nodeStack.push(t),t=t.left;return e}hasNext(){return this.nodeStack.length>0}peek(){if(this.nodeStack.length===0)return null;const t=this.nodeStack[this.nodeStack.length-1];return{key:t.key,value:t.value}}}class Et{constructor(t,e,n,s,i){this.key=t,this.value=e,this.color=n??Et.RED,this.left=s??Et.EMPTY,this.right=i??Et.EMPTY,this.size=this.left.size+1+this.right.size}copy(t,e,n,s,i){return new Et(t??this.key,e??this.value,n??this.color,s??this.left,i??this.right)}isEmpty(){return!1}inorderTraversal(t){return this.left.inorderTraversal(t)||t(this.key,this.value)||this.right.inorderTraversal(t)}reverseTraversal(t){return this.right.reverseTraversal(t)||t(this.key,this.value)||this.left.reverseTraversal(t)}min(){return this.left.isEmpty()?this:this.left.min()}minKey(){return this.min().key}maxKey(){return this.right.isEmpty()?this.key:this.right.maxKey()}insert(t,e,n){let s=this;const i=n(t,s.key);return s=i<0?s.copy(null,null,null,s.left.insert(t,e,n),null):i===0?s.copy(null,e,null,null,null):s.copy(null,null,null,null,s.right.insert(t,e,n)),s.fixUp()}removeMin(){if(this.left.isEmpty())return Et.EMPTY;let t=this;return t.left.isRed()||t.left.left.isRed()||(t=t.moveRedLeft()),t=t.copy(null,null,null,t.left.removeMin(),null),t.fixUp()}remove(t,e){let n,s=this;if(e(t,s.key)<0)s.left.isEmpty()||s.left.isRed()||s.left.left.isRed()||(s=s.moveRedLeft()),s=s.copy(null,null,null,s.left.remove(t,e),null);else{if(s.left.isRed()&&(s=s.rotateRight()),s.right.isEmpty()||s.right.isRed()||s.right.left.isRed()||(s=s.moveRedRight()),e(t,s.key)===0){if(s.right.isEmpty())return Et.EMPTY;n=s.right.min(),s=s.copy(n.key,n.value,null,null,s.right.removeMin())}s=s.copy(null,null,null,null,s.right.remove(t,e))}return s.fixUp()}isRed(){return this.color}fixUp(){let t=this;return t.right.isRed()&&!t.left.isRed()&&(t=t.rotateLeft()),t.left.isRed()&&t.left.left.isRed()&&(t=t.rotateRight()),t.left.isRed()&&t.right.isRed()&&(t=t.colorFlip()),t}moveRedLeft(){let t=this.colorFlip();return t.right.left.isRed()&&(t=t.copy(null,null,null,null,t.right.rotateRight()),t=t.rotateLeft(),t=t.colorFlip()),t}moveRedRight(){let t=this.colorFlip();return t.left.left.isRed()&&(t=t.rotateRight(),t=t.colorFlip()),t}rotateLeft(){const t=this.copy(null,null,Et.RED,null,this.right.left);return this.right.copy(null,null,this.color,t,null)}rotateRight(){const t=this.copy(null,null,Et.RED,this.left.right,null);return this.left.copy(null,null,this.color,null,t)}colorFlip(){const t=this.left.copy(null,null,!this.left.color,null,null),e=this.right.copy(null,null,!this.right.color,null,null);return this.copy(null,null,!this.color,t,e)}checkMaxDepth(){const t=this.check();return Math.pow(2,t)<=this.size+1}check(){if(this.isRed()&&this.left.isRed())throw O(43730,{key:this.key,value:this.value});if(this.right.isRed())throw O(14113,{key:this.key,value:this.value});const t=this.left.check();if(t!==this.right.check())throw O(27949);return t+(this.isRed()?0:1)}}Et.EMPTY=null,Et.RED=!0,Et.BLACK=!1;Et.EMPTY=new class{constructor(){this.size=0}get key(){throw O(57766)}get value(){throw O(16141)}get color(){throw O(16727)}get left(){throw O(29726)}get right(){throw O(36894)}copy(t,e,n,s,i){return this}insert(t,e,n){return new Et(t,e)}remove(t,e){return this}isEmpty(){return!0}inorderTraversal(t){return!1}reverseTraversal(t){return!1}minKey(){return null}maxKey(){return null}isRed(){return!1}checkMaxDepth(){return!0}check(){return 0}};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class tt{constructor(t){this.comparator=t,this.data=new nt(this.comparator)}has(t){return this.data.get(t)!==null}first(){return this.data.minKey()}last(){return this.data.maxKey()}get size(){return this.data.size}indexOf(t){return this.data.indexOf(t)}forEach(t){this.data.inorderTraversal(((e,n)=>(t(e),!1)))}forEachInRange(t,e){const n=this.data.getIteratorFrom(t[0]);for(;n.hasNext();){const s=n.getNext();if(this.comparator(s.key,t[1])>=0)return;e(s.key)}}forEachWhile(t,e){let n;for(n=e!==void 0?this.data.getIteratorFrom(e):this.data.getIterator();n.hasNext();)if(!t(n.getNext().key))return}firstAfterOrEqual(t){const e=this.data.getIteratorFrom(t);return e.hasNext()?e.getNext().key:null}getIterator(){return new _c(this.data.getIterator())}getIteratorFrom(t){return new _c(this.data.getIteratorFrom(t))}add(t){return this.copy(this.data.remove(t).insert(t,!0))}delete(t){return this.has(t)?this.copy(this.data.remove(t)):this}isEmpty(){return this.data.isEmpty()}unionWith(t){let e=this;return e.size<t.size&&(e=t,t=this),t.forEach((n=>{e=e.add(n)})),e}isEqual(t){if(!(t instanceof tt)||this.size!==t.size)return!1;const e=this.data.getIterator(),n=t.data.getIterator();for(;e.hasNext();){const s=e.getNext().key,i=n.getNext().key;if(this.comparator(s,i)!==0)return!1}return!0}toArray(){const t=[];return this.forEach((e=>{t.push(e)})),t}toString(){const t=[];return this.forEach((e=>t.push(e))),"SortedSet("+t.toString()+")"}copy(t){const e=new tt(this.comparator);return e.data=t,e}}class _c{constructor(t){this.iter=t}getNext(){return this.iter.getNext().key}hasNext(){return this.iter.hasNext()}}function ln(r){return r.hasNext()?r.getNext():void 0}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class xt{constructor(t){this.fields=t,t.sort(ot.comparator)}static empty(){return new xt([])}unionWith(t){let e=new tt(ot.comparator);for(const n of this.fields)e=e.add(n);for(const n of t)e=e.add(n);return new xt(e.toArray())}covers(t){for(const e of this.fields)if(e.isPrefixOf(t))return!0;return!1}isEqual(t){return An(this.fields,t.fields,((e,n)=>e.isEqual(n)))}}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class _h extends Error{constructor(){super(...arguments),this.name="Base64DecodeError"}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ht{constructor(t){this.binaryString=t}static fromBase64String(t){const e=(function(s){try{return atob(s)}catch(i){throw typeof DOMException<"u"&&i instanceof DOMException?new _h("Invalid base64 string: "+i):i}})(t);return new ht(e)}static fromUint8Array(t){const e=(function(s){let i="";for(let a=0;a<s.length;++a)i+=String.fromCharCode(s[a]);return i})(t);return new ht(e)}[Symbol.iterator](){let t=0;return{next:()=>t<this.binaryString.length?{value:this.binaryString.charCodeAt(t++),done:!1}:{value:void 0,done:!0}}}toBase64(){return(function(e){return btoa(e)})(this.binaryString)}toUint8Array(){return(function(e){const n=new Uint8Array(e.length);for(let s=0;s<e.length;s++)n[s]=e.charCodeAt(s);return n})(this.binaryString)}approximateByteSize(){return 2*this.binaryString.length}compareTo(t){return U(this.binaryString,t.binaryString)}isEqual(t){return this.binaryString===t.binaryString}}ht.EMPTY_BYTE_STRING=new ht("");const dp=new RegExp(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.(\d+))?Z$/);function ne(r){if(L(!!r,39018),typeof r=="string"){let t=0;const e=dp.exec(r);if(L(!!e,46558,{timestamp:r}),e[1]){let s=e[1];s=(s+"000000000").substr(0,9),t=Number(s)}const n=new Date(r);return{seconds:Math.floor(n.getTime()/1e3),nanos:t}}return{seconds:it(r.seconds),nanos:it(r.nanos)}}function it(r){return typeof r=="number"?r:typeof r=="string"?Number(r):0}function re(r){return typeof r=="string"?ht.fromBase64String(r):ht.fromUint8Array(r)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const yh="server_timestamp",Ih="__type__",Eh="__previous_value__",Th="__local_write_time__";function ia(r){var e,n;return((n=(((e=r==null?void 0:r.mapValue)==null?void 0:e.fields)||{})[Ih])==null?void 0:n.stringValue)===yh}function pi(r){const t=r.mapValue.fields[Eh];return ia(t)?pi(t):t}function Br(r){const t=ne(r.mapValue.fields[Th].timestampValue);return new X(t.seconds,t.nanos)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class fp{constructor(t,e,n,s,i,a,u,l,d,f,g){this.databaseId=t,this.appId=e,this.persistenceKey=n,this.host=s,this.ssl=i,this.forceLongPolling=a,this.autoDetectLongPolling=u,this.longPollingOptions=l,this.useFetchStreams=d,this.isUsingEmulator=f,this.apiKey=g}}const Hs="(default)";class Ye{constructor(t,e){this.projectId=t,this.database=e||Hs}static empty(){return new Ye("","")}get isDefaultDatabase(){return this.database===Hs}isEqual(t){return t instanceof Ye&&t.projectId===this.projectId&&t.database===this.database}}function mp(r,t){if(!Object.prototype.hasOwnProperty.apply(r.options,["projectId"]))throw new C(S.INVALID_ARGUMENT,'"projectId" not provided in firebase.initializeApp.');return new Ye(r.options.projectId,t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const oa="__type__",wh="__max__",pe={mapValue:{fields:{__type__:{stringValue:wh}}}},aa="__vector__",Cn="value",xs={nullValue:"NULL_VALUE"};function we(r){return"nullValue"in r?0:"booleanValue"in r?1:"integerValue"in r||"doubleValue"in r?2:"timestampValue"in r?3:"stringValue"in r?5:"bytesValue"in r?6:"referenceValue"in r?7:"geoPointValue"in r?8:"arrayValue"in r?9:"mapValue"in r?ia(r)?4:vh(r)?9007199254740991:_i(r)?10:11:O(28295,{value:r})}function Yt(r,t){if(r===t)return!0;const e=we(r);if(e!==we(t))return!1;switch(e){case 0:case 9007199254740991:return!0;case 1:return r.booleanValue===t.booleanValue;case 4:return Br(r).isEqual(Br(t));case 3:return(function(s,i){if(typeof s.timestampValue=="string"&&typeof i.timestampValue=="string"&&s.timestampValue.length===i.timestampValue.length)return s.timestampValue===i.timestampValue;const a=ne(s.timestampValue),u=ne(i.timestampValue);return a.seconds===u.seconds&&a.nanos===u.nanos})(r,t);case 5:return r.stringValue===t.stringValue;case 6:return(function(s,i){return re(s.bytesValue).isEqual(re(i.bytesValue))})(r,t);case 7:return r.referenceValue===t.referenceValue;case 8:return(function(s,i){return it(s.geoPointValue.latitude)===it(i.geoPointValue.latitude)&&it(s.geoPointValue.longitude)===it(i.geoPointValue.longitude)})(r,t);case 2:return(function(s,i){if("integerValue"in s&&"integerValue"in i)return it(s.integerValue)===it(i.integerValue);if("doubleValue"in s&&"doubleValue"in i){const a=it(s.doubleValue),u=it(i.doubleValue);return a===u?Mr(a)===Mr(u):isNaN(a)&&isNaN(u)}return!1})(r,t);case 9:return An(r.arrayValue.values||[],t.arrayValue.values||[],Yt);case 10:case 11:return(function(s,i){const a=s.mapValue.fields||{},u=i.mapValue.fields||{};if(pc(a)!==pc(u))return!1;for(const l in a)if(a.hasOwnProperty(l)&&(u[l]===void 0||!Yt(a[l],u[l])))return!1;return!0})(r,t);default:return O(52216,{left:r})}}function Ur(r,t){return(r.values||[]).find((e=>Yt(e,t)))!==void 0}function ve(r,t){if(r===t)return 0;const e=we(r),n=we(t);if(e!==n)return U(e,n);switch(e){case 0:case 9007199254740991:return 0;case 1:return U(r.booleanValue,t.booleanValue);case 2:return(function(i,a){const u=it(i.integerValue||i.doubleValue),l=it(a.integerValue||a.doubleValue);return u<l?-1:u>l?1:u===l?0:isNaN(u)?isNaN(l)?0:-1:1})(r,t);case 3:return yc(r.timestampValue,t.timestampValue);case 4:return yc(Br(r),Br(t));case 5:return bo(r.stringValue,t.stringValue);case 6:return(function(i,a){const u=re(i),l=re(a);return u.compareTo(l)})(r.bytesValue,t.bytesValue);case 7:return(function(i,a){const u=i.split("/"),l=a.split("/");for(let d=0;d<u.length&&d<l.length;d++){const f=U(u[d],l[d]);if(f!==0)return f}return U(u.length,l.length)})(r.referenceValue,t.referenceValue);case 8:return(function(i,a){const u=U(it(i.latitude),it(a.latitude));return u!==0?u:U(it(i.longitude),it(a.longitude))})(r.geoPointValue,t.geoPointValue);case 9:return Ic(r.arrayValue,t.arrayValue);case 10:return(function(i,a){var E,V,D,k;const u=i.fields||{},l=a.fields||{},d=(E=u[Cn])==null?void 0:E.arrayValue,f=(V=l[Cn])==null?void 0:V.arrayValue,g=U(((D=d==null?void 0:d.values)==null?void 0:D.length)||0,((k=f==null?void 0:f.values)==null?void 0:k.length)||0);return g!==0?g:Ic(d,f)})(r.mapValue,t.mapValue);case 11:return(function(i,a){if(i===pe.mapValue&&a===pe.mapValue)return 0;if(i===pe.mapValue)return 1;if(a===pe.mapValue)return-1;const u=i.fields||{},l=Object.keys(u),d=a.fields||{},f=Object.keys(d);l.sort(),f.sort();for(let g=0;g<l.length&&g<f.length;++g){const E=bo(l[g],f[g]);if(E!==0)return E;const V=ve(u[l[g]],d[f[g]]);if(V!==0)return V}return U(l.length,f.length)})(r.mapValue,t.mapValue);default:throw O(23264,{he:e})}}function yc(r,t){if(typeof r=="string"&&typeof t=="string"&&r.length===t.length)return U(r,t);const e=ne(r),n=ne(t),s=U(e.seconds,n.seconds);return s!==0?s:U(e.nanos,n.nanos)}function Ic(r,t){const e=r.values||[],n=t.values||[];for(let s=0;s<e.length&&s<n.length;++s){const i=ve(e[s],n[s]);if(i)return i}return U(e.length,n.length)}function Dn(r){return Do(r)}function Do(r){return"nullValue"in r?"null":"booleanValue"in r?""+r.booleanValue:"integerValue"in r?""+r.integerValue:"doubleValue"in r?""+r.doubleValue:"timestampValue"in r?(function(e){const n=ne(e);return`time(${n.seconds},${n.nanos})`})(r.timestampValue):"stringValue"in r?r.stringValue:"bytesValue"in r?(function(e){return re(e).toBase64()})(r.bytesValue):"referenceValue"in r?(function(e){return N.fromName(e).toString()})(r.referenceValue):"geoPointValue"in r?(function(e){return`geo(${e.latitude},${e.longitude})`})(r.geoPointValue):"arrayValue"in r?(function(e){let n="[",s=!0;for(const i of e.values||[])s?s=!1:n+=",",n+=Do(i);return n+"]"})(r.arrayValue):"mapValue"in r?(function(e){const n=Object.keys(e.fields||{}).sort();let s="{",i=!0;for(const a of n)i?i=!1:s+=",",s+=`${a}:${Do(e.fields[a])}`;return s+"}"})(r.mapValue):O(61005,{value:r})}function Ns(r){switch(we(r)){case 0:case 1:return 4;case 2:return 8;case 3:case 8:return 16;case 4:const t=pi(r);return t?16+Ns(t):16;case 5:return 2*r.stringValue.length;case 6:return re(r.bytesValue).approximateByteSize();case 7:return r.referenceValue.length;case 9:return(function(n){return(n.values||[]).reduce(((s,i)=>s+Ns(i)),0)})(r.arrayValue);case 10:case 11:return(function(n){let s=0;return Ve(n.fields,((i,a)=>{s+=i.length+Ns(a)})),s})(r.mapValue);default:throw O(13486,{value:r})}}function qr(r,t){return{referenceValue:`projects/${r.projectId}/databases/${r.database}/documents/${t.path.canonicalString()}`}}function xo(r){return!!r&&"integerValue"in r}function jr(r){return!!r&&"arrayValue"in r}function Ec(r){return!!r&&"nullValue"in r}function Tc(r){return!!r&&"doubleValue"in r&&isNaN(Number(r.doubleValue))}function ks(r){return!!r&&"mapValue"in r}function _i(r){var e,n;return((n=(((e=r==null?void 0:r.mapValue)==null?void 0:e.fields)||{})[oa])==null?void 0:n.stringValue)===aa}function Sr(r){if(r.geoPointValue)return{geoPointValue:{...r.geoPointValue}};if(r.timestampValue&&typeof r.timestampValue=="object")return{timestampValue:{...r.timestampValue}};if(r.mapValue){const t={mapValue:{fields:{}}};return Ve(r.mapValue.fields,((e,n)=>t.mapValue.fields[e]=Sr(n))),t}if(r.arrayValue){const t={arrayValue:{values:[]}};for(let e=0;e<(r.arrayValue.values||[]).length;++e)t.arrayValue.values[e]=Sr(r.arrayValue.values[e]);return t}return{...r}}function vh(r){return(((r.mapValue||{}).fields||{}).__type__||{}).stringValue===wh}const Ah={mapValue:{fields:{[oa]:{stringValue:aa},[Cn]:{arrayValue:{}}}}};function gp(r){return"nullValue"in r?xs:"booleanValue"in r?{booleanValue:!1}:"integerValue"in r||"doubleValue"in r?{doubleValue:NaN}:"timestampValue"in r?{timestampValue:{seconds:Number.MIN_SAFE_INTEGER}}:"stringValue"in r?{stringValue:""}:"bytesValue"in r?{bytesValue:""}:"referenceValue"in r?qr(Ye.empty(),N.empty()):"geoPointValue"in r?{geoPointValue:{latitude:-90,longitude:-180}}:"arrayValue"in r?{arrayValue:{}}:"mapValue"in r?_i(r)?Ah:{mapValue:{}}:O(35942,{value:r})}function pp(r){return"nullValue"in r?{booleanValue:!1}:"booleanValue"in r?{doubleValue:NaN}:"integerValue"in r||"doubleValue"in r?{timestampValue:{seconds:Number.MIN_SAFE_INTEGER}}:"timestampValue"in r?{stringValue:""}:"stringValue"in r?{bytesValue:""}:"bytesValue"in r?qr(Ye.empty(),N.empty()):"referenceValue"in r?{geoPointValue:{latitude:-90,longitude:-180}}:"geoPointValue"in r?{arrayValue:{}}:"arrayValue"in r?Ah:"mapValue"in r?_i(r)?{mapValue:{}}:pe:O(61959,{value:r})}function wc(r,t){const e=ve(r.value,t.value);return e!==0?e:r.inclusive&&!t.inclusive?-1:!r.inclusive&&t.inclusive?1:0}function vc(r,t){const e=ve(r.value,t.value);return e!==0?e:r.inclusive&&!t.inclusive?1:!r.inclusive&&t.inclusive?-1:0}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class bt{constructor(t){this.value=t}static empty(){return new bt({mapValue:{}})}field(t){if(t.isEmpty())return this.value;{let e=this.value;for(let n=0;n<t.length-1;++n)if(e=(e.mapValue.fields||{})[t.get(n)],!ks(e))return null;return e=(e.mapValue.fields||{})[t.lastSegment()],e||null}}set(t,e){this.getFieldsMap(t.popLast())[t.lastSegment()]=Sr(e)}setAll(t){let e=ot.emptyPath(),n={},s=[];t.forEach(((a,u)=>{if(!e.isImmediateParentOf(u)){const l=this.getFieldsMap(e);this.applyChanges(l,n,s),n={},s=[],e=u.popLast()}a?n[u.lastSegment()]=Sr(a):s.push(u.lastSegment())}));const i=this.getFieldsMap(e);this.applyChanges(i,n,s)}delete(t){const e=this.field(t.popLast());ks(e)&&e.mapValue.fields&&delete e.mapValue.fields[t.lastSegment()]}isEqual(t){return Yt(this.value,t.value)}getFieldsMap(t){let e=this.value;e.mapValue.fields||(e.mapValue={fields:{}});for(let n=0;n<t.length;++n){let s=e.mapValue.fields[t.get(n)];ks(s)&&s.mapValue.fields||(s={mapValue:{fields:{}}},e.mapValue.fields[t.get(n)]=s),e=s}return e.mapValue.fields}applyChanges(t,e,n){Ve(e,((s,i)=>t[s]=i));for(const s of n)delete t[s]}clone(){return new bt(Sr(this.value))}}function bh(r){const t=[];return Ve(r.fields,((e,n)=>{const s=new ot([e]);if(ks(n)){const i=bh(n.mapValue).fields;if(i.length===0)t.push(s);else for(const a of i)t.push(s.child(a))}else t.push(s)})),new xt(t)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ct{constructor(t,e,n,s,i,a,u){this.key=t,this.documentType=e,this.version=n,this.readTime=s,this.createTime=i,this.data=a,this.documentState=u}static newInvalidDocument(t){return new ct(t,0,B.min(),B.min(),B.min(),bt.empty(),0)}static newFoundDocument(t,e,n,s){return new ct(t,1,e,B.min(),n,s,0)}static newNoDocument(t,e){return new ct(t,2,e,B.min(),B.min(),bt.empty(),0)}static newUnknownDocument(t,e){return new ct(t,3,e,B.min(),B.min(),bt.empty(),2)}convertToFoundDocument(t,e){return!this.createTime.isEqual(B.min())||this.documentType!==2&&this.documentType!==0||(this.createTime=t),this.version=t,this.documentType=1,this.data=e,this.documentState=0,this}convertToNoDocument(t){return this.version=t,this.documentType=2,this.data=bt.empty(),this.documentState=0,this}convertToUnknownDocument(t){return this.version=t,this.documentType=3,this.data=bt.empty(),this.documentState=2,this}setHasCommittedMutations(){return this.documentState=2,this}setHasLocalMutations(){return this.documentState=1,this.version=B.min(),this}setReadTime(t){return this.readTime=t,this}get hasLocalMutations(){return this.documentState===1}get hasCommittedMutations(){return this.documentState===2}get hasPendingWrites(){return this.hasLocalMutations||this.hasCommittedMutations}isValidDocument(){return this.documentType!==0}isFoundDocument(){return this.documentType===1}isNoDocument(){return this.documentType===2}isUnknownDocument(){return this.documentType===3}isEqual(t){return t instanceof ct&&this.key.isEqual(t.key)&&this.version.isEqual(t.version)&&this.documentType===t.documentType&&this.documentState===t.documentState&&this.data.isEqual(t.data)}mutableCopy(){return new ct(this.key,this.documentType,this.version,this.readTime,this.createTime,this.data.clone(),this.documentState)}toString(){return`Document(${this.key}, ${this.version}, ${JSON.stringify(this.data.value)}, {createTime: ${this.createTime}}), {documentType: ${this.documentType}}), {documentState: ${this.documentState}})`}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class xn{constructor(t,e){this.position=t,this.inclusive=e}}function Ac(r,t,e){let n=0;for(let s=0;s<r.position.length;s++){const i=t[s],a=r.position[s];if(i.field.isKeyField()?n=N.comparator(N.fromName(a.referenceValue),e.key):n=ve(a,e.data.field(i.field)),i.dir==="desc"&&(n*=-1),n!==0)break}return n}function bc(r,t){if(r===null)return t===null;if(t===null||r.inclusive!==t.inclusive||r.position.length!==t.position.length)return!1;for(let e=0;e<r.position.length;e++)if(!Yt(r.position[e],t.position[e]))return!1;return!0}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class zr{constructor(t,e="asc"){this.field=t,this.dir=e}}function _p(r,t){return r.dir===t.dir&&r.field.isEqual(t.field)}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Rh{}class G extends Rh{constructor(t,e,n){super(),this.field=t,this.op=e,this.value=n}static create(t,e,n){return t.isKeyField()?e==="in"||e==="not-in"?this.createKeyFieldInFilter(t,e,n):new yp(t,e,n):e==="array-contains"?new Tp(t,n):e==="in"?new xh(t,n):e==="not-in"?new wp(t,n):e==="array-contains-any"?new vp(t,n):new G(t,e,n)}static createKeyFieldInFilter(t,e,n){return e==="in"?new Ip(t,n):new Ep(t,n)}matches(t){const e=t.data.field(this.field);return this.op==="!="?e!==null&&e.nullValue===void 0&&this.matchesComparison(ve(e,this.value)):e!==null&&we(this.value)===we(e)&&this.matchesComparison(ve(e,this.value))}matchesComparison(t){switch(this.op){case"<":return t<0;case"<=":return t<=0;case"==":return t===0;case"!=":return t!==0;case">":return t>0;case">=":return t>=0;default:return O(47266,{operator:this.op})}}isInequality(){return["<","<=",">",">=","!=","not-in"].indexOf(this.op)>=0}getFlattenedFilters(){return[this]}getFilters(){return[this]}}class Z extends Rh{constructor(t,e){super(),this.filters=t,this.op=e,this.Pe=null}static create(t,e){return new Z(t,e)}matches(t){return Nn(this)?this.filters.find((e=>!e.matches(t)))===void 0:this.filters.find((e=>e.matches(t)))!==void 0}getFlattenedFilters(){return this.Pe!==null||(this.Pe=this.filters.reduce(((t,e)=>t.concat(e.getFlattenedFilters())),[])),this.Pe}getFilters(){return Object.assign([],this.filters)}}function Nn(r){return r.op==="and"}function No(r){return r.op==="or"}function ua(r){return Sh(r)&&Nn(r)}function Sh(r){for(const t of r.filters)if(t instanceof Z)return!1;return!0}function ko(r){if(r instanceof G)return r.field.canonicalString()+r.op.toString()+Dn(r.value);if(ua(r))return r.filters.map((t=>ko(t))).join(",");{const t=r.filters.map((e=>ko(e))).join(",");return`${r.op}(${t})`}}function Vh(r,t){return r instanceof G?(function(n,s){return s instanceof G&&n.op===s.op&&n.field.isEqual(s.field)&&Yt(n.value,s.value)})(r,t):r instanceof Z?(function(n,s){return s instanceof Z&&n.op===s.op&&n.filters.length===s.filters.length?n.filters.reduce(((i,a,u)=>i&&Vh(a,s.filters[u])),!0):!1})(r,t):void O(19439)}function Ph(r,t){const e=r.filters.concat(t);return Z.create(e,r.op)}function Ch(r){return r instanceof G?(function(e){return`${e.field.canonicalString()} ${e.op} ${Dn(e.value)}`})(r):r instanceof Z?(function(e){return e.op.toString()+" {"+e.getFilters().map(Ch).join(" ,")+"}"})(r):"Filter"}class yp extends G{constructor(t,e,n){super(t,e,n),this.key=N.fromName(n.referenceValue)}matches(t){const e=N.comparator(t.key,this.key);return this.matchesComparison(e)}}class Ip extends G{constructor(t,e){super(t,"in",e),this.keys=Dh("in",e)}matches(t){return this.keys.some((e=>e.isEqual(t.key)))}}class Ep extends G{constructor(t,e){super(t,"not-in",e),this.keys=Dh("not-in",e)}matches(t){return!this.keys.some((e=>e.isEqual(t.key)))}}function Dh(r,t){var e;return(((e=t.arrayValue)==null?void 0:e.values)||[]).map((n=>N.fromName(n.referenceValue)))}class Tp extends G{constructor(t,e){super(t,"array-contains",e)}matches(t){const e=t.data.field(this.field);return jr(e)&&Ur(e.arrayValue,this.value)}}class xh extends G{constructor(t,e){super(t,"in",e)}matches(t){const e=t.data.field(this.field);return e!==null&&Ur(this.value.arrayValue,e)}}class wp extends G{constructor(t,e){super(t,"not-in",e)}matches(t){if(Ur(this.value.arrayValue,{nullValue:"NULL_VALUE"}))return!1;const e=t.data.field(this.field);return e!==null&&e.nullValue===void 0&&!Ur(this.value.arrayValue,e)}}class vp extends G{constructor(t,e){super(t,"array-contains-any",e)}matches(t){const e=t.data.field(this.field);return!(!jr(e)||!e.arrayValue.values)&&e.arrayValue.values.some((n=>Ur(this.value.arrayValue,n)))}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Ap{constructor(t,e=null,n=[],s=[],i=null,a=null,u=null){this.path=t,this.collectionGroup=e,this.orderBy=n,this.filters=s,this.limit=i,this.startAt=a,this.endAt=u,this.Te=null}}function Mo(r,t=null,e=[],n=[],s=null,i=null,a=null){return new Ap(r,t,e,n,s,i,a)}function Xe(r){const t=F(r);if(t.Te===null){let e=t.path.canonicalString();t.collectionGroup!==null&&(e+="|cg:"+t.collectionGroup),e+="|f:",e+=t.filters.map((n=>ko(n))).join(","),e+="|ob:",e+=t.orderBy.map((n=>(function(i){return i.field.canonicalString()+i.dir})(n))).join(","),di(t.limit)||(e+="|l:",e+=t.limit),t.startAt&&(e+="|lb:",e+=t.startAt.inclusive?"b:":"a:",e+=t.startAt.position.map((n=>Dn(n))).join(",")),t.endAt&&(e+="|ub:",e+=t.endAt.inclusive?"a:":"b:",e+=t.endAt.position.map((n=>Dn(n))).join(",")),t.Te=e}return t.Te}function Wr(r,t){if(r.limit!==t.limit||r.orderBy.length!==t.orderBy.length)return!1;for(let e=0;e<r.orderBy.length;e++)if(!_p(r.orderBy[e],t.orderBy[e]))return!1;if(r.filters.length!==t.filters.length)return!1;for(let e=0;e<r.filters.length;e++)if(!Vh(r.filters[e],t.filters[e]))return!1;return r.collectionGroup===t.collectionGroup&&!!r.path.isEqual(t.path)&&!!bc(r.startAt,t.startAt)&&bc(r.endAt,t.endAt)}function Qs(r){return N.isDocumentKey(r.path)&&r.collectionGroup===null&&r.filters.length===0}function Ws(r,t){return r.filters.filter((e=>e instanceof G&&e.field.isEqual(t)))}function Rc(r,t,e){let n=xs,s=!0;for(const i of Ws(r,t)){let a=xs,u=!0;switch(i.op){case"<":case"<=":a=gp(i.value);break;case"==":case"in":case">=":a=i.value;break;case">":a=i.value,u=!1;break;case"!=":case"not-in":a=xs}wc({value:n,inclusive:s},{value:a,inclusive:u})<0&&(n=a,s=u)}if(e!==null){for(let i=0;i<r.orderBy.length;++i)if(r.orderBy[i].field.isEqual(t)){const a=e.position[i];wc({value:n,inclusive:s},{value:a,inclusive:e.inclusive})<0&&(n=a,s=e.inclusive);break}}return{value:n,inclusive:s}}function Sc(r,t,e){let n=pe,s=!0;for(const i of Ws(r,t)){let a=pe,u=!0;switch(i.op){case">=":case">":a=pp(i.value),u=!1;break;case"==":case"in":case"<=":a=i.value;break;case"<":a=i.value,u=!1;break;case"!=":case"not-in":a=pe}vc({value:n,inclusive:s},{value:a,inclusive:u})>0&&(n=a,s=u)}if(e!==null){for(let i=0;i<r.orderBy.length;++i)if(r.orderBy[i].field.isEqual(t)){const a=e.position[i];vc({value:n,inclusive:s},{value:a,inclusive:e.inclusive})>0&&(n=a,s=e.inclusive);break}}return{value:n,inclusive:s}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class $n{constructor(t,e=null,n=[],s=[],i=null,a="F",u=null,l=null){this.path=t,this.collectionGroup=e,this.explicitOrderBy=n,this.filters=s,this.limit=i,this.limitType=a,this.startAt=u,this.endAt=l,this.Ee=null,this.Ie=null,this.Re=null,this.startAt,this.endAt}}function Nh(r,t,e,n,s,i,a,u){return new $n(r,t,e,n,s,i,a,u)}function Jr(r){return new $n(r)}function Vc(r){return r.filters.length===0&&r.limit===null&&r.startAt==null&&r.endAt==null&&(r.explicitOrderBy.length===0||r.explicitOrderBy.length===1&&r.explicitOrderBy[0].field.isKeyField())}function bp(r){return N.isDocumentKey(r.path)&&r.collectionGroup===null&&r.filters.length===0}function kh(r){return r.collectionGroup!==null}function Vr(r){const t=F(r);if(t.Ee===null){t.Ee=[];const e=new Set;for(const i of t.explicitOrderBy)t.Ee.push(i),e.add(i.field.canonicalString());const n=t.explicitOrderBy.length>0?t.explicitOrderBy[t.explicitOrderBy.length-1].dir:"asc";(function(a){let u=new tt(ot.comparator);return a.filters.forEach((l=>{l.getFlattenedFilters().forEach((d=>{d.isInequality()&&(u=u.add(d.field))}))})),u})(t).forEach((i=>{e.has(i.canonicalString())||i.isKeyField()||t.Ee.push(new zr(i,n))})),e.has(ot.keyField().canonicalString())||t.Ee.push(new zr(ot.keyField(),n))}return t.Ee}function Ot(r){const t=F(r);return t.Ie||(t.Ie=Rp(t,Vr(r))),t.Ie}function Rp(r,t){if(r.limitType==="F")return Mo(r.path,r.collectionGroup,t,r.filters,r.limit,r.startAt,r.endAt);{t=t.map((s=>{const i=s.dir==="desc"?"asc":"desc";return new zr(s.field,i)}));const e=r.endAt?new xn(r.endAt.position,r.endAt.inclusive):null,n=r.startAt?new xn(r.startAt.position,r.startAt.inclusive):null;return Mo(r.path,r.collectionGroup,t,r.filters,r.limit,e,n)}}function Oo(r,t){const e=r.filters.concat([t]);return new $n(r.path,r.collectionGroup,r.explicitOrderBy.slice(),e,r.limit,r.limitType,r.startAt,r.endAt)}function Sp(r,t){const e=r.explicitOrderBy.concat([t]);return new $n(r.path,r.collectionGroup,e,r.filters.slice(),r.limit,r.limitType,r.startAt,r.endAt)}function Fo(r,t,e){return new $n(r.path,r.collectionGroup,r.explicitOrderBy.slice(),r.filters.slice(),t,e,r.startAt,r.endAt)}function yi(r,t){return Wr(Ot(r),Ot(t))&&r.limitType===t.limitType}function Mh(r){return`${Xe(Ot(r))}|lt:${r.limitType}`}function pn(r){return`Query(target=${(function(e){let n=e.path.canonicalString();return e.collectionGroup!==null&&(n+=" collectionGroup="+e.collectionGroup),e.filters.length>0&&(n+=`, filters: [${e.filters.map((s=>Ch(s))).join(", ")}]`),di(e.limit)||(n+=", limit: "+e.limit),e.orderBy.length>0&&(n+=`, orderBy: [${e.orderBy.map((s=>(function(a){return`${a.field.canonicalString()} (${a.dir})`})(s))).join(", ")}]`),e.startAt&&(n+=", startAt: ",n+=e.startAt.inclusive?"b:":"a:",n+=e.startAt.position.map((s=>Dn(s))).join(",")),e.endAt&&(n+=", endAt: ",n+=e.endAt.inclusive?"a:":"b:",n+=e.endAt.position.map((s=>Dn(s))).join(",")),`Target(${n})`})(Ot(r))}; limitType=${r.limitType})`}function Yr(r,t){return t.isFoundDocument()&&(function(n,s){const i=s.key.path;return n.collectionGroup!==null?s.key.hasCollectionId(n.collectionGroup)&&n.path.isPrefixOf(i):N.isDocumentKey(n.path)?n.path.isEqual(i):n.path.isImmediateParentOf(i)})(r,t)&&(function(n,s){for(const i of Vr(n))if(!i.field.isKeyField()&&s.data.field(i.field)===null)return!1;return!0})(r,t)&&(function(n,s){for(const i of n.filters)if(!i.matches(s))return!1;return!0})(r,t)&&(function(n,s){return!(n.startAt&&!(function(a,u,l){const d=Ac(a,u,l);return a.inclusive?d<=0:d<0})(n.startAt,Vr(n),s)||n.endAt&&!(function(a,u,l){const d=Ac(a,u,l);return a.inclusive?d>=0:d>0})(n.endAt,Vr(n),s))})(r,t)}function Oh(r){return r.collectionGroup||(r.path.length%2==1?r.path.lastSegment():r.path.get(r.path.length-2))}function Fh(r){return(t,e)=>{let n=!1;for(const s of Vr(r)){const i=Vp(s,t,e);if(i!==0)return i;n=n||s.field.isKeyField()}return 0}}function Vp(r,t,e){const n=r.field.isKeyField()?N.comparator(t.key,e.key):(function(i,a,u){const l=a.data.field(i),d=u.data.field(i);return l!==null&&d!==null?ve(l,d):O(42886)})(r.field,t,e);switch(r.dir){case"asc":return n;case"desc":return-1*n;default:return O(19790,{direction:r.dir})}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class se{constructor(t,e){this.mapKeyFn=t,this.equalsFn=e,this.inner={},this.innerSize=0}get(t){const e=this.mapKeyFn(t),n=this.inner[e];if(n!==void 0){for(const[s,i]of n)if(this.equalsFn(s,t))return i}}has(t){return this.get(t)!==void 0}set(t,e){const n=this.mapKeyFn(t),s=this.inner[n];if(s===void 0)return this.inner[n]=[[t,e]],void this.innerSize++;for(let i=0;i<s.length;i++)if(this.equalsFn(s[i][0],t))return void(s[i]=[t,e]);s.push([t,e]),this.innerSize++}delete(t){const e=this.mapKeyFn(t),n=this.inner[e];if(n===void 0)return!1;for(let s=0;s<n.length;s++)if(this.equalsFn(n[s][0],t))return n.length===1?delete this.inner[e]:n.splice(s,1),this.innerSize--,!0;return!1}forEach(t){Ve(this.inner,((e,n)=>{for(const[s,i]of n)t(s,i)}))}isEmpty(){return ph(this.inner)}size(){return this.innerSize}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Pp=new nt(N.comparator);function Mt(){return Pp}const Lh=new nt(N.comparator);function yr(...r){let t=Lh;for(const e of r)t=t.insert(e.key,e);return t}function Bh(r){let t=Lh;return r.forEach(((e,n)=>t=t.insert(e,n.overlayedDocument))),t}function Wt(){return Pr()}function Uh(){return Pr()}function Pr(){return new se((r=>r.toString()),((r,t)=>r.isEqual(t)))}const Cp=new nt(N.comparator),Dp=new tt(N.comparator);function $(...r){let t=Dp;for(const e of r)t=t.add(e);return t}const xp=new tt(U);function ca(){return xp}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function la(r,t){if(r.useProto3Json){if(isNaN(t))return{doubleValue:"NaN"};if(t===1/0)return{doubleValue:"Infinity"};if(t===-1/0)return{doubleValue:"-Infinity"}}return{doubleValue:Mr(t)?"-0":t}}function qh(r){return{integerValue:""+r}}function Np(r,t){return ih(t)?qh(t):la(r,t)}/**
 * @license
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Ii{constructor(){this._=void 0}}function kp(r,t,e){return r instanceof kn?(function(s,i){const a={fields:{[Ih]:{stringValue:yh},[Th]:{timestampValue:{seconds:s.seconds,nanos:s.nanoseconds}}}};return i&&ia(i)&&(i=pi(i)),i&&(a.fields[Eh]=i),{mapValue:a}})(e,t):r instanceof Mn?zh(r,t):r instanceof On?$h(r,t):(function(s,i){const a=jh(s,i),u=Pc(a)+Pc(s.Ae);return xo(a)&&xo(s.Ae)?qh(u):la(s.serializer,u)})(r,t)}function Mp(r,t,e){return r instanceof Mn?zh(r,t):r instanceof On?$h(r,t):e}function jh(r,t){return r instanceof $r?(function(n){return xo(n)||(function(i){return!!i&&"doubleValue"in i})(n)})(t)?t:{integerValue:0}:null}class kn extends Ii{}class Mn extends Ii{constructor(t){super(),this.elements=t}}function zh(r,t){const e=Gh(t);for(const n of r.elements)e.some((s=>Yt(s,n)))||e.push(n);return{arrayValue:{values:e}}}class On extends Ii{constructor(t){super(),this.elements=t}}function $h(r,t){let e=Gh(t);for(const n of r.elements)e=e.filter((s=>!Yt(s,n)));return{arrayValue:{values:e}}}class $r extends Ii{constructor(t,e){super(),this.serializer=t,this.Ae=e}}function Pc(r){return it(r.integerValue||r.doubleValue)}function Gh(r){return jr(r)&&r.arrayValue.values?r.arrayValue.values.slice():[]}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Kh{constructor(t,e){this.field=t,this.transform=e}}function Op(r,t){return r.field.isEqual(t.field)&&(function(n,s){return n instanceof Mn&&s instanceof Mn||n instanceof On&&s instanceof On?An(n.elements,s.elements,Yt):n instanceof $r&&s instanceof $r?Yt(n.Ae,s.Ae):n instanceof kn&&s instanceof kn})(r.transform,t.transform)}class Fp{constructor(t,e){this.version=t,this.transformResults=e}}class pt{constructor(t,e){this.updateTime=t,this.exists=e}static none(){return new pt}static exists(t){return new pt(void 0,t)}static updateTime(t){return new pt(t)}get isNone(){return this.updateTime===void 0&&this.exists===void 0}isEqual(t){return this.exists===t.exists&&(this.updateTime?!!t.updateTime&&this.updateTime.isEqual(t.updateTime):!t.updateTime)}}function Ms(r,t){return r.updateTime!==void 0?t.isFoundDocument()&&t.version.isEqual(r.updateTime):r.exists===void 0||r.exists===t.isFoundDocument()}class Ei{}function Hh(r,t){if(!r.hasLocalMutations||t&&t.fields.length===0)return null;if(t===null)return r.isNoDocument()?new Xr(r.key,pt.none()):new Gn(r.key,r.data,pt.none());{const e=r.data,n=bt.empty();let s=new tt(ot.comparator);for(let i of t.fields)if(!s.has(i)){let a=e.field(i);a===null&&i.length>1&&(i=i.popLast(),a=e.field(i)),a===null?n.delete(i):n.set(i,a),s=s.add(i)}return new ie(r.key,n,new xt(s.toArray()),pt.none())}}function Lp(r,t,e){r instanceof Gn?(function(s,i,a){const u=s.value.clone(),l=Dc(s.fieldTransforms,i,a.transformResults);u.setAll(l),i.convertToFoundDocument(a.version,u).setHasCommittedMutations()})(r,t,e):r instanceof ie?(function(s,i,a){if(!Ms(s.precondition,i))return void i.convertToUnknownDocument(a.version);const u=Dc(s.fieldTransforms,i,a.transformResults),l=i.data;l.setAll(Qh(s)),l.setAll(u),i.convertToFoundDocument(a.version,l).setHasCommittedMutations()})(r,t,e):(function(s,i,a){i.convertToNoDocument(a.version).setHasCommittedMutations()})(0,t,e)}function Cr(r,t,e,n){return r instanceof Gn?(function(i,a,u,l){if(!Ms(i.precondition,a))return u;const d=i.value.clone(),f=xc(i.fieldTransforms,l,a);return d.setAll(f),a.convertToFoundDocument(a.version,d).setHasLocalMutations(),null})(r,t,e,n):r instanceof ie?(function(i,a,u,l){if(!Ms(i.precondition,a))return u;const d=xc(i.fieldTransforms,l,a),f=a.data;return f.setAll(Qh(i)),f.setAll(d),a.convertToFoundDocument(a.version,f).setHasLocalMutations(),u===null?null:u.unionWith(i.fieldMask.fields).unionWith(i.fieldTransforms.map((g=>g.field)))})(r,t,e,n):(function(i,a,u){return Ms(i.precondition,a)?(a.convertToNoDocument(a.version).setHasLocalMutations(),null):u})(r,t,e)}function Bp(r,t){let e=null;for(const n of r.fieldTransforms){const s=t.data.field(n.field),i=jh(n.transform,s||null);i!=null&&(e===null&&(e=bt.empty()),e.set(n.field,i))}return e||null}function Cc(r,t){return r.type===t.type&&!!r.key.isEqual(t.key)&&!!r.precondition.isEqual(t.precondition)&&!!(function(n,s){return n===void 0&&s===void 0||!(!n||!s)&&An(n,s,((i,a)=>Op(i,a)))})(r.fieldTransforms,t.fieldTransforms)&&(r.type===0?r.value.isEqual(t.value):r.type!==1||r.data.isEqual(t.data)&&r.fieldMask.isEqual(t.fieldMask))}class Gn extends Ei{constructor(t,e,n,s=[]){super(),this.key=t,this.value=e,this.precondition=n,this.fieldTransforms=s,this.type=0}getFieldMask(){return null}}class ie extends Ei{constructor(t,e,n,s,i=[]){super(),this.key=t,this.data=e,this.fieldMask=n,this.precondition=s,this.fieldTransforms=i,this.type=1}getFieldMask(){return this.fieldMask}}function Qh(r){const t=new Map;return r.fieldMask.fields.forEach((e=>{if(!e.isEmpty()){const n=r.data.field(e);t.set(e,n)}})),t}function Dc(r,t,e){const n=new Map;L(r.length===e.length,32656,{Ve:e.length,de:r.length});for(let s=0;s<e.length;s++){const i=r[s],a=i.transform,u=t.data.field(i.field);n.set(i.field,Mp(a,u,e[s]))}return n}function xc(r,t,e){const n=new Map;for(const s of r){const i=s.transform,a=e.data.field(s.field);n.set(s.field,kp(i,a,t))}return n}class Xr extends Ei{constructor(t,e){super(),this.key=t,this.precondition=e,this.type=2,this.fieldTransforms=[]}getFieldMask(){return null}}class Wh extends Ei{constructor(t,e){super(),this.key=t,this.precondition=e,this.type=3,this.fieldTransforms=[]}getFieldMask(){return null}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ha{constructor(t,e,n,s){this.batchId=t,this.localWriteTime=e,this.baseMutations=n,this.mutations=s}applyToRemoteDocument(t,e){const n=e.mutationResults;for(let s=0;s<this.mutations.length;s++){const i=this.mutations[s];i.key.isEqual(t.key)&&Lp(i,t,n[s])}}applyToLocalView(t,e){for(const n of this.baseMutations)n.key.isEqual(t.key)&&(e=Cr(n,t,e,this.localWriteTime));for(const n of this.mutations)n.key.isEqual(t.key)&&(e=Cr(n,t,e,this.localWriteTime));return e}applyToLocalDocumentSet(t,e){const n=Uh();return this.mutations.forEach((s=>{const i=t.get(s.key),a=i.overlayedDocument;let u=this.applyToLocalView(a,i.mutatedFields);u=e.has(s.key)?null:u;const l=Hh(a,u);l!==null&&n.set(s.key,l),a.isValidDocument()||a.convertToNoDocument(B.min())})),n}keys(){return this.mutations.reduce(((t,e)=>t.add(e.key)),$())}isEqual(t){return this.batchId===t.batchId&&An(this.mutations,t.mutations,((e,n)=>Cc(e,n)))&&An(this.baseMutations,t.baseMutations,((e,n)=>Cc(e,n)))}}class da{constructor(t,e,n,s){this.batch=t,this.commitVersion=e,this.mutationResults=n,this.docVersions=s}static from(t,e,n){L(t.mutations.length===n.length,58842,{me:t.mutations.length,fe:n.length});let s=(function(){return Cp})();const i=t.mutations;for(let a=0;a<i.length;a++)s=s.insert(i[a].key,n[a].version);return new da(t,e,n,s)}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class fa{constructor(t,e){this.largestBatchId=t,this.mutation=e}getKey(){return this.mutation.key}isEqual(t){return t!==null&&this.mutation===t.mutation}toString(){return`Overlay{
      largestBatchId: ${this.largestBatchId},
      mutation: ${this.mutation.toString()}
    }`}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Up{constructor(t,e){this.count=t,this.unchangedNames=e}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */var dt,H;function qp(r){switch(r){case S.OK:return O(64938);case S.CANCELLED:case S.UNKNOWN:case S.DEADLINE_EXCEEDED:case S.RESOURCE_EXHAUSTED:case S.INTERNAL:case S.UNAVAILABLE:case S.UNAUTHENTICATED:return!1;case S.INVALID_ARGUMENT:case S.NOT_FOUND:case S.ALREADY_EXISTS:case S.PERMISSION_DENIED:case S.FAILED_PRECONDITION:case S.ABORTED:case S.OUT_OF_RANGE:case S.UNIMPLEMENTED:case S.DATA_LOSS:return!0;default:return O(15467,{code:r})}}function Jh(r){if(r===void 0)return lt("GRPC error has no .code"),S.UNKNOWN;switch(r){case dt.OK:return S.OK;case dt.CANCELLED:return S.CANCELLED;case dt.UNKNOWN:return S.UNKNOWN;case dt.DEADLINE_EXCEEDED:return S.DEADLINE_EXCEEDED;case dt.RESOURCE_EXHAUSTED:return S.RESOURCE_EXHAUSTED;case dt.INTERNAL:return S.INTERNAL;case dt.UNAVAILABLE:return S.UNAVAILABLE;case dt.UNAUTHENTICATED:return S.UNAUTHENTICATED;case dt.INVALID_ARGUMENT:return S.INVALID_ARGUMENT;case dt.NOT_FOUND:return S.NOT_FOUND;case dt.ALREADY_EXISTS:return S.ALREADY_EXISTS;case dt.PERMISSION_DENIED:return S.PERMISSION_DENIED;case dt.FAILED_PRECONDITION:return S.FAILED_PRECONDITION;case dt.ABORTED:return S.ABORTED;case dt.OUT_OF_RANGE:return S.OUT_OF_RANGE;case dt.UNIMPLEMENTED:return S.UNIMPLEMENTED;case dt.DATA_LOSS:return S.DATA_LOSS;default:return O(39323,{code:r})}}(H=dt||(dt={}))[H.OK=0]="OK",H[H.CANCELLED=1]="CANCELLED",H[H.UNKNOWN=2]="UNKNOWN",H[H.INVALID_ARGUMENT=3]="INVALID_ARGUMENT",H[H.DEADLINE_EXCEEDED=4]="DEADLINE_EXCEEDED",H[H.NOT_FOUND=5]="NOT_FOUND",H[H.ALREADY_EXISTS=6]="ALREADY_EXISTS",H[H.PERMISSION_DENIED=7]="PERMISSION_DENIED",H[H.UNAUTHENTICATED=16]="UNAUTHENTICATED",H[H.RESOURCE_EXHAUSTED=8]="RESOURCE_EXHAUSTED",H[H.FAILED_PRECONDITION=9]="FAILED_PRECONDITION",H[H.ABORTED=10]="ABORTED",H[H.OUT_OF_RANGE=11]="OUT_OF_RANGE",H[H.UNIMPLEMENTED=12]="UNIMPLEMENTED",H[H.INTERNAL=13]="INTERNAL",H[H.UNAVAILABLE=14]="UNAVAILABLE",H[H.DATA_LOSS=15]="DATA_LOSS";/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function jp(){return new TextEncoder}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const zp=new Ie([4294967295,4294967295],0);function Nc(r){const t=jp().encode(r),e=new $l;return e.update(t),new Uint8Array(e.digest())}function kc(r){const t=new DataView(r.buffer),e=t.getUint32(0,!0),n=t.getUint32(4,!0),s=t.getUint32(8,!0),i=t.getUint32(12,!0);return[new Ie([e,n],0),new Ie([s,i],0)]}class ma{constructor(t,e,n){if(this.bitmap=t,this.padding=e,this.hashCount=n,e<0||e>=8)throw new Ir(`Invalid padding: ${e}`);if(n<0)throw new Ir(`Invalid hash count: ${n}`);if(t.length>0&&this.hashCount===0)throw new Ir(`Invalid hash count: ${n}`);if(t.length===0&&e!==0)throw new Ir(`Invalid padding when bitmap length is 0: ${e}`);this.ge=8*t.length-e,this.pe=Ie.fromNumber(this.ge)}ye(t,e,n){let s=t.add(e.multiply(Ie.fromNumber(n)));return s.compare(zp)===1&&(s=new Ie([s.getBits(0),s.getBits(1)],0)),s.modulo(this.pe).toNumber()}we(t){return!!(this.bitmap[Math.floor(t/8)]&1<<t%8)}mightContain(t){if(this.ge===0)return!1;const e=Nc(t),[n,s]=kc(e);for(let i=0;i<this.hashCount;i++){const a=this.ye(n,s,i);if(!this.we(a))return!1}return!0}static create(t,e,n){const s=t%8==0?0:8-t%8,i=new Uint8Array(Math.ceil(t/8)),a=new ma(i,s,e);return n.forEach((u=>a.insert(u))),a}insert(t){if(this.ge===0)return;const e=Nc(t),[n,s]=kc(e);for(let i=0;i<this.hashCount;i++){const a=this.ye(n,s,i);this.Se(a)}}Se(t){const e=Math.floor(t/8),n=t%8;this.bitmap[e]|=1<<n}}class Ir extends Error{constructor(){super(...arguments),this.name="BloomFilterError"}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Zr{constructor(t,e,n,s,i){this.snapshotVersion=t,this.targetChanges=e,this.targetMismatches=n,this.documentUpdates=s,this.resolvedLimboDocuments=i}static createSynthesizedRemoteEventForCurrentChange(t,e,n){const s=new Map;return s.set(t,ts.createSynthesizedTargetChangeForCurrentChange(t,e,n)),new Zr(B.min(),s,new nt(U),Mt(),$())}}class ts{constructor(t,e,n,s,i){this.resumeToken=t,this.current=e,this.addedDocuments=n,this.modifiedDocuments=s,this.removedDocuments=i}static createSynthesizedTargetChangeForCurrentChange(t,e,n){return new ts(n,e,$(),$(),$())}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Os{constructor(t,e,n,s){this.be=t,this.removedTargetIds=e,this.key=n,this.De=s}}class Yh{constructor(t,e){this.targetId=t,this.Ce=e}}class Xh{constructor(t,e,n=ht.EMPTY_BYTE_STRING,s=null){this.state=t,this.targetIds=e,this.resumeToken=n,this.cause=s}}class Mc{constructor(){this.ve=0,this.Fe=Oc(),this.Me=ht.EMPTY_BYTE_STRING,this.xe=!1,this.Oe=!0}get current(){return this.xe}get resumeToken(){return this.Me}get Ne(){return this.ve!==0}get Be(){return this.Oe}Le(t){t.approximateByteSize()>0&&(this.Oe=!0,this.Me=t)}ke(){let t=$(),e=$(),n=$();return this.Fe.forEach(((s,i)=>{switch(i){case 0:t=t.add(s);break;case 2:e=e.add(s);break;case 1:n=n.add(s);break;default:O(38017,{changeType:i})}})),new ts(this.Me,this.xe,t,e,n)}qe(){this.Oe=!1,this.Fe=Oc()}Ke(t,e){this.Oe=!0,this.Fe=this.Fe.insert(t,e)}Ue(t){this.Oe=!0,this.Fe=this.Fe.remove(t)}$e(){this.ve+=1}We(){this.ve-=1,L(this.ve>=0,3241,{ve:this.ve})}Qe(){this.Oe=!0,this.xe=!0}}class $p{constructor(t){this.Ge=t,this.ze=new Map,this.je=Mt(),this.Je=vs(),this.He=vs(),this.Ze=new nt(U)}Xe(t){for(const e of t.be)t.De&&t.De.isFoundDocument()?this.Ye(e,t.De):this.et(e,t.key,t.De);for(const e of t.removedTargetIds)this.et(e,t.key,t.De)}tt(t){this.forEachTarget(t,(e=>{const n=this.nt(e);switch(t.state){case 0:this.rt(e)&&n.Le(t.resumeToken);break;case 1:n.We(),n.Ne||n.qe(),n.Le(t.resumeToken);break;case 2:n.We(),n.Ne||this.removeTarget(e);break;case 3:this.rt(e)&&(n.Qe(),n.Le(t.resumeToken));break;case 4:this.rt(e)&&(this.it(e),n.Le(t.resumeToken));break;default:O(56790,{state:t.state})}}))}forEachTarget(t,e){t.targetIds.length>0?t.targetIds.forEach(e):this.ze.forEach(((n,s)=>{this.rt(s)&&e(s)}))}st(t){const e=t.targetId,n=t.Ce.count,s=this.ot(e);if(s){const i=s.target;if(Qs(i))if(n===0){const a=new N(i.path);this.et(e,a,ct.newNoDocument(a,B.min()))}else L(n===1,20013,{expectedCount:n});else{const a=this._t(e);if(a!==n){const u=this.ut(t),l=u?this.ct(u,t,a):1;if(l!==0){this.it(e);const d=l===2?"TargetPurposeExistenceFilterMismatchBloom":"TargetPurposeExistenceFilterMismatch";this.Ze=this.Ze.insert(e,d)}}}}}ut(t){const e=t.Ce.unchangedNames;if(!e||!e.bits)return null;const{bits:{bitmap:n="",padding:s=0},hashCount:i=0}=e;let a,u;try{a=re(n).toUint8Array()}catch(l){if(l instanceof _h)return vn("Decoding the base64 bloom filter in existence filter failed ("+l.message+"); ignoring the bloom filter and falling back to full re-query."),null;throw l}try{u=new ma(a,s,i)}catch(l){return vn(l instanceof Ir?"BloomFilter error: ":"Applying bloom filter failed: ",l),null}return u.ge===0?null:u}ct(t,e,n){return e.Ce.count===n-this.Pt(t,e.targetId)?0:2}Pt(t,e){const n=this.Ge.getRemoteKeysForTarget(e);let s=0;return n.forEach((i=>{const a=this.Ge.ht(),u=`projects/${a.projectId}/databases/${a.database}/documents/${i.path.canonicalString()}`;t.mightContain(u)||(this.et(e,i,null),s++)})),s}Tt(t){const e=new Map;this.ze.forEach(((i,a)=>{const u=this.ot(a);if(u){if(i.current&&Qs(u.target)){const l=new N(u.target.path);this.Et(l).has(a)||this.It(a,l)||this.et(a,l,ct.newNoDocument(l,t))}i.Be&&(e.set(a,i.ke()),i.qe())}}));let n=$();this.He.forEach(((i,a)=>{let u=!0;a.forEachWhile((l=>{const d=this.ot(l);return!d||d.purpose==="TargetPurposeLimboResolution"||(u=!1,!1)})),u&&(n=n.add(i))})),this.je.forEach(((i,a)=>a.setReadTime(t)));const s=new Zr(t,e,this.Ze,this.je,n);return this.je=Mt(),this.Je=vs(),this.He=vs(),this.Ze=new nt(U),s}Ye(t,e){if(!this.rt(t))return;const n=this.It(t,e.key)?2:0;this.nt(t).Ke(e.key,n),this.je=this.je.insert(e.key,e),this.Je=this.Je.insert(e.key,this.Et(e.key).add(t)),this.He=this.He.insert(e.key,this.Rt(e.key).add(t))}et(t,e,n){if(!this.rt(t))return;const s=this.nt(t);this.It(t,e)?s.Ke(e,1):s.Ue(e),this.He=this.He.insert(e,this.Rt(e).delete(t)),this.He=this.He.insert(e,this.Rt(e).add(t)),n&&(this.je=this.je.insert(e,n))}removeTarget(t){this.ze.delete(t)}_t(t){const e=this.nt(t).ke();return this.Ge.getRemoteKeysForTarget(t).size+e.addedDocuments.size-e.removedDocuments.size}$e(t){this.nt(t).$e()}nt(t){let e=this.ze.get(t);return e||(e=new Mc,this.ze.set(t,e)),e}Rt(t){let e=this.He.get(t);return e||(e=new tt(U),this.He=this.He.insert(t,e)),e}Et(t){let e=this.Je.get(t);return e||(e=new tt(U),this.Je=this.Je.insert(t,e)),e}rt(t){const e=this.ot(t)!==null;return e||P("WatchChangeAggregator","Detected inactive target",t),e}ot(t){const e=this.ze.get(t);return e&&e.Ne?null:this.Ge.At(t)}it(t){this.ze.set(t,new Mc),this.Ge.getRemoteKeysForTarget(t).forEach((e=>{this.et(t,e,null)}))}It(t,e){return this.Ge.getRemoteKeysForTarget(t).has(e)}}function vs(){return new nt(N.comparator)}function Oc(){return new nt(N.comparator)}const Gp={asc:"ASCENDING",desc:"DESCENDING"},Kp={"<":"LESS_THAN","<=":"LESS_THAN_OR_EQUAL",">":"GREATER_THAN",">=":"GREATER_THAN_OR_EQUAL","==":"EQUAL","!=":"NOT_EQUAL","array-contains":"ARRAY_CONTAINS",in:"IN","not-in":"NOT_IN","array-contains-any":"ARRAY_CONTAINS_ANY"},Hp={and:"AND",or:"OR"};class Qp{constructor(t,e){this.databaseId=t,this.useProto3Json=e}}function Lo(r,t){return r.useProto3Json||di(t)?t:{value:t}}function Fn(r,t){return r.useProto3Json?`${new Date(1e3*t.seconds).toISOString().replace(/\.\d*/,"").replace("Z","")}.${("000000000"+t.nanoseconds).slice(-9)}Z`:{seconds:""+t.seconds,nanos:t.nanoseconds}}function Zh(r,t){return r.useProto3Json?t.toBase64():t.toUint8Array()}function Wp(r,t){return Fn(r,t.toTimestamp())}function Pt(r){return L(!!r,49232),B.fromTimestamp((function(e){const n=ne(e);return new X(n.seconds,n.nanos)})(r))}function ga(r,t){return Bo(r,t).canonicalString()}function Bo(r,t){const e=(function(s){return new Y(["projects",s.projectId,"databases",s.database])})(r).child("documents");return t===void 0?e:e.child(t)}function td(r){const t=Y.fromString(r);return L(cd(t),10190,{key:t.toString()}),t}function Js(r,t){return ga(r.databaseId,t.path)}function Qe(r,t){const e=td(t);if(e.get(1)!==r.databaseId.projectId)throw new C(S.INVALID_ARGUMENT,"Tried to deserialize key from different project: "+e.get(1)+" vs "+r.databaseId.projectId);if(e.get(3)!==r.databaseId.database)throw new C(S.INVALID_ARGUMENT,"Tried to deserialize key from different database: "+e.get(3)+" vs "+r.databaseId.database);return new N(rd(e))}function ed(r,t){return ga(r.databaseId,t)}function nd(r){const t=td(r);return t.length===4?Y.emptyPath():rd(t)}function Uo(r){return new Y(["projects",r.databaseId.projectId,"databases",r.databaseId.database]).canonicalString()}function rd(r){return L(r.length>4&&r.get(4)==="documents",29091,{key:r.toString()}),r.popFirst(5)}function Fc(r,t,e){return{name:Js(r,t),fields:e.value.mapValue.fields}}function Jp(r,t,e){const n=Qe(r,t.name),s=Pt(t.updateTime),i=t.createTime?Pt(t.createTime):B.min(),a=new bt({mapValue:{fields:t.fields}}),u=ct.newFoundDocument(n,s,i,a);return e&&u.setHasCommittedMutations(),e?u.setHasCommittedMutations():u}function Yp(r,t){let e;if("targetChange"in t){t.targetChange;const n=(function(d){return d==="NO_CHANGE"?0:d==="ADD"?1:d==="REMOVE"?2:d==="CURRENT"?3:d==="RESET"?4:O(39313,{state:d})})(t.targetChange.targetChangeType||"NO_CHANGE"),s=t.targetChange.targetIds||[],i=(function(d,f){return d.useProto3Json?(L(f===void 0||typeof f=="string",58123),ht.fromBase64String(f||"")):(L(f===void 0||f instanceof Buffer||f instanceof Uint8Array,16193),ht.fromUint8Array(f||new Uint8Array))})(r,t.targetChange.resumeToken),a=t.targetChange.cause,u=a&&(function(d){const f=d.code===void 0?S.UNKNOWN:Jh(d.code);return new C(f,d.message||"")})(a);e=new Xh(n,s,i,u||null)}else if("documentChange"in t){t.documentChange;const n=t.documentChange;n.document,n.document.name,n.document.updateTime;const s=Qe(r,n.document.name),i=Pt(n.document.updateTime),a=n.document.createTime?Pt(n.document.createTime):B.min(),u=new bt({mapValue:{fields:n.document.fields}}),l=ct.newFoundDocument(s,i,a,u),d=n.targetIds||[],f=n.removedTargetIds||[];e=new Os(d,f,l.key,l)}else if("documentDelete"in t){t.documentDelete;const n=t.documentDelete;n.document;const s=Qe(r,n.document),i=n.readTime?Pt(n.readTime):B.min(),a=ct.newNoDocument(s,i),u=n.removedTargetIds||[];e=new Os([],u,a.key,a)}else if("documentRemove"in t){t.documentRemove;const n=t.documentRemove;n.document;const s=Qe(r,n.document),i=n.removedTargetIds||[];e=new Os([],i,s,null)}else{if(!("filter"in t))return O(11601,{Vt:t});{t.filter;const n=t.filter;n.targetId;const{count:s=0,unchangedNames:i}=n,a=new Up(s,i),u=n.targetId;e=new Yh(u,a)}}return e}function Ys(r,t){let e;if(t instanceof Gn)e={update:Fc(r,t.key,t.value)};else if(t instanceof Xr)e={delete:Js(r,t.key)};else if(t instanceof ie)e={update:Fc(r,t.key,t.data),updateMask:r_(t.fieldMask)};else{if(!(t instanceof Wh))return O(16599,{dt:t.type});e={verify:Js(r,t.key)}}return t.fieldTransforms.length>0&&(e.updateTransforms=t.fieldTransforms.map((n=>(function(i,a){const u=a.transform;if(u instanceof kn)return{fieldPath:a.field.canonicalString(),setToServerValue:"REQUEST_TIME"};if(u instanceof Mn)return{fieldPath:a.field.canonicalString(),appendMissingElements:{values:u.elements}};if(u instanceof On)return{fieldPath:a.field.canonicalString(),removeAllFromArray:{values:u.elements}};if(u instanceof $r)return{fieldPath:a.field.canonicalString(),increment:u.Ae};throw O(20930,{transform:a.transform})})(0,n)))),t.precondition.isNone||(e.currentDocument=(function(s,i){return i.updateTime!==void 0?{updateTime:Wp(s,i.updateTime)}:i.exists!==void 0?{exists:i.exists}:O(27497)})(r,t.precondition)),e}function qo(r,t){const e=t.currentDocument?(function(i){return i.updateTime!==void 0?pt.updateTime(Pt(i.updateTime)):i.exists!==void 0?pt.exists(i.exists):pt.none()})(t.currentDocument):pt.none(),n=t.updateTransforms?t.updateTransforms.map((s=>(function(a,u){let l=null;if("setToServerValue"in u)L(u.setToServerValue==="REQUEST_TIME",16630,{proto:u}),l=new kn;else if("appendMissingElements"in u){const f=u.appendMissingElements.values||[];l=new Mn(f)}else if("removeAllFromArray"in u){const f=u.removeAllFromArray.values||[];l=new On(f)}else"increment"in u?l=new $r(a,u.increment):O(16584,{proto:u});const d=ot.fromServerFormat(u.fieldPath);return new Kh(d,l)})(r,s))):[];if(t.update){t.update.name;const s=Qe(r,t.update.name),i=new bt({mapValue:{fields:t.update.fields}});if(t.updateMask){const a=(function(l){const d=l.fieldPaths||[];return new xt(d.map((f=>ot.fromServerFormat(f))))})(t.updateMask);return new ie(s,i,a,e,n)}return new Gn(s,i,e,n)}if(t.delete){const s=Qe(r,t.delete);return new Xr(s,e)}if(t.verify){const s=Qe(r,t.verify);return new Wh(s,e)}return O(1463,{proto:t})}function Xp(r,t){return r&&r.length>0?(L(t!==void 0,14353),r.map((e=>(function(s,i){let a=s.updateTime?Pt(s.updateTime):Pt(i);return a.isEqual(B.min())&&(a=Pt(i)),new Fp(a,s.transformResults||[])})(e,t)))):[]}function sd(r,t){return{documents:[ed(r,t.path)]}}function id(r,t){const e={structuredQuery:{}},n=t.path;let s;t.collectionGroup!==null?(s=n,e.structuredQuery.from=[{collectionId:t.collectionGroup,allDescendants:!0}]):(s=n.popLast(),e.structuredQuery.from=[{collectionId:n.lastSegment()}]),e.parent=ed(r,s);const i=(function(d){if(d.length!==0)return ud(Z.create(d,"and"))})(t.filters);i&&(e.structuredQuery.where=i);const a=(function(d){if(d.length!==0)return d.map((f=>(function(E){return{field:_n(E.field),direction:t_(E.dir)}})(f)))})(t.orderBy);a&&(e.structuredQuery.orderBy=a);const u=Lo(r,t.limit);return u!==null&&(e.structuredQuery.limit=u),t.startAt&&(e.structuredQuery.startAt=(function(d){return{before:d.inclusive,values:d.position}})(t.startAt)),t.endAt&&(e.structuredQuery.endAt=(function(d){return{before:!d.inclusive,values:d.position}})(t.endAt)),{ft:e,parent:s}}function od(r){let t=nd(r.parent);const e=r.structuredQuery,n=e.from?e.from.length:0;let s=null;if(n>0){L(n===1,65062);const f=e.from[0];f.allDescendants?s=f.collectionId:t=t.child(f.collectionId)}let i=[];e.where&&(i=(function(g){const E=ad(g);return E instanceof Z&&ua(E)?E.getFilters():[E]})(e.where));let a=[];e.orderBy&&(a=(function(g){return g.map((E=>(function(D){return new zr(yn(D.field),(function(M){switch(M){case"ASCENDING":return"asc";case"DESCENDING":return"desc";default:return}})(D.direction))})(E)))})(e.orderBy));let u=null;e.limit&&(u=(function(g){let E;return E=typeof g=="object"?g.value:g,di(E)?null:E})(e.limit));let l=null;e.startAt&&(l=(function(g){const E=!!g.before,V=g.values||[];return new xn(V,E)})(e.startAt));let d=null;return e.endAt&&(d=(function(g){const E=!g.before,V=g.values||[];return new xn(V,E)})(e.endAt)),Nh(t,s,a,i,u,"F",l,d)}function Zp(r,t){const e=(function(s){switch(s){case"TargetPurposeListen":return null;case"TargetPurposeExistenceFilterMismatch":return"existence-filter-mismatch";case"TargetPurposeExistenceFilterMismatchBloom":return"existence-filter-mismatch-bloom";case"TargetPurposeLimboResolution":return"limbo-document";default:return O(28987,{purpose:s})}})(t.purpose);return e==null?null:{"goog-listen-tags":e}}function ad(r){return r.unaryFilter!==void 0?(function(e){switch(e.unaryFilter.op){case"IS_NAN":const n=yn(e.unaryFilter.field);return G.create(n,"==",{doubleValue:NaN});case"IS_NULL":const s=yn(e.unaryFilter.field);return G.create(s,"==",{nullValue:"NULL_VALUE"});case"IS_NOT_NAN":const i=yn(e.unaryFilter.field);return G.create(i,"!=",{doubleValue:NaN});case"IS_NOT_NULL":const a=yn(e.unaryFilter.field);return G.create(a,"!=",{nullValue:"NULL_VALUE"});case"OPERATOR_UNSPECIFIED":return O(61313);default:return O(60726)}})(r):r.fieldFilter!==void 0?(function(e){return G.create(yn(e.fieldFilter.field),(function(s){switch(s){case"EQUAL":return"==";case"NOT_EQUAL":return"!=";case"GREATER_THAN":return">";case"GREATER_THAN_OR_EQUAL":return">=";case"LESS_THAN":return"<";case"LESS_THAN_OR_EQUAL":return"<=";case"ARRAY_CONTAINS":return"array-contains";case"IN":return"in";case"NOT_IN":return"not-in";case"ARRAY_CONTAINS_ANY":return"array-contains-any";case"OPERATOR_UNSPECIFIED":return O(58110);default:return O(50506)}})(e.fieldFilter.op),e.fieldFilter.value)})(r):r.compositeFilter!==void 0?(function(e){return Z.create(e.compositeFilter.filters.map((n=>ad(n))),(function(s){switch(s){case"AND":return"and";case"OR":return"or";default:return O(1026)}})(e.compositeFilter.op))})(r):O(30097,{filter:r})}function t_(r){return Gp[r]}function e_(r){return Kp[r]}function n_(r){return Hp[r]}function _n(r){return{fieldPath:r.canonicalString()}}function yn(r){return ot.fromServerFormat(r.fieldPath)}function ud(r){return r instanceof G?(function(e){if(e.op==="=="){if(Tc(e.value))return{unaryFilter:{field:_n(e.field),op:"IS_NAN"}};if(Ec(e.value))return{unaryFilter:{field:_n(e.field),op:"IS_NULL"}}}else if(e.op==="!="){if(Tc(e.value))return{unaryFilter:{field:_n(e.field),op:"IS_NOT_NAN"}};if(Ec(e.value))return{unaryFilter:{field:_n(e.field),op:"IS_NOT_NULL"}}}return{fieldFilter:{field:_n(e.field),op:e_(e.op),value:e.value}}})(r):r instanceof Z?(function(e){const n=e.getFilters().map((s=>ud(s)));return n.length===1?n[0]:{compositeFilter:{op:n_(e.op),filters:n}}})(r):O(54877,{filter:r})}function r_(r){const t=[];return r.fields.forEach((e=>t.push(e.canonicalString()))),{fieldPaths:t}}function cd(r){return r.length>=4&&r.get(0)==="projects"&&r.get(2)==="databases"}function ld(r){return!!r&&typeof r._toProto=="function"&&r._protoValueType==="ProtoValue"}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Zt{constructor(t,e,n,s,i=B.min(),a=B.min(),u=ht.EMPTY_BYTE_STRING,l=null){this.target=t,this.targetId=e,this.purpose=n,this.sequenceNumber=s,this.snapshotVersion=i,this.lastLimboFreeSnapshotVersion=a,this.resumeToken=u,this.expectedCount=l}withSequenceNumber(t){return new Zt(this.target,this.targetId,this.purpose,t,this.snapshotVersion,this.lastLimboFreeSnapshotVersion,this.resumeToken,this.expectedCount)}withResumeToken(t,e){return new Zt(this.target,this.targetId,this.purpose,this.sequenceNumber,e,this.lastLimboFreeSnapshotVersion,t,null)}withExpectedCount(t){return new Zt(this.target,this.targetId,this.purpose,this.sequenceNumber,this.snapshotVersion,this.lastLimboFreeSnapshotVersion,this.resumeToken,t)}withLastLimboFreeSnapshotVersion(t){return new Zt(this.target,this.targetId,this.purpose,this.sequenceNumber,this.snapshotVersion,t,this.resumeToken,this.expectedCount)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class hd{constructor(t){this.yt=t}}function s_(r,t){let e;if(t.document)e=Jp(r.yt,t.document,!!t.hasCommittedMutations);else if(t.noDocument){const n=N.fromSegments(t.noDocument.path),s=tn(t.noDocument.readTime);e=ct.newNoDocument(n,s),t.hasCommittedMutations&&e.setHasCommittedMutations()}else{if(!t.unknownDocument)return O(56709);{const n=N.fromSegments(t.unknownDocument.path),s=tn(t.unknownDocument.version);e=ct.newUnknownDocument(n,s)}}return t.readTime&&e.setReadTime((function(s){const i=new X(s[0],s[1]);return B.fromTimestamp(i)})(t.readTime)),e}function Lc(r,t){const e=t.key,n={prefixPath:e.getCollectionPath().popLast().toArray(),collectionGroup:e.collectionGroup,documentId:e.path.lastSegment(),readTime:Xs(t.readTime),hasCommittedMutations:t.hasCommittedMutations};if(t.isFoundDocument())n.document=(function(i,a){return{name:Js(i,a.key),fields:a.data.value.mapValue.fields,updateTime:Fn(i,a.version.toTimestamp()),createTime:Fn(i,a.createTime.toTimestamp())}})(r.yt,t);else if(t.isNoDocument())n.noDocument={path:e.path.toArray(),readTime:Ze(t.version)};else{if(!t.isUnknownDocument())return O(57904,{document:t});n.unknownDocument={path:e.path.toArray(),version:Ze(t.version)}}return n}function Xs(r){const t=r.toTimestamp();return[t.seconds,t.nanoseconds]}function Ze(r){const t=r.toTimestamp();return{seconds:t.seconds,nanoseconds:t.nanoseconds}}function tn(r){const t=new X(r.seconds,r.nanoseconds);return B.fromTimestamp(t)}function je(r,t){const e=(t.baseMutations||[]).map((i=>qo(r.yt,i)));for(let i=0;i<t.mutations.length-1;++i){const a=t.mutations[i];if(i+1<t.mutations.length&&t.mutations[i+1].transform!==void 0){const u=t.mutations[i+1];a.updateTransforms=u.transform.fieldTransforms,t.mutations.splice(i+1,1),++i}}const n=t.mutations.map((i=>qo(r.yt,i))),s=X.fromMillis(t.localWriteTimeMs);return new ha(t.batchId,s,e,n)}function Er(r){const t=tn(r.readTime),e=r.lastLimboFreeSnapshotVersion!==void 0?tn(r.lastLimboFreeSnapshotVersion):B.min();let n;return n=(function(i){return i.documents!==void 0})(r.query)?(function(i){const a=i.documents.length;return L(a===1,1966,{count:a}),Ot(Jr(nd(i.documents[0])))})(r.query):(function(i){return Ot(od(i))})(r.query),new Zt(n,r.targetId,"TargetPurposeListen",r.lastListenSequenceNumber,t,e,ht.fromBase64String(r.resumeToken))}function dd(r,t){const e=Ze(t.snapshotVersion),n=Ze(t.lastLimboFreeSnapshotVersion);let s;s=Qs(t.target)?sd(r.yt,t.target):id(r.yt,t.target).ft;const i=t.resumeToken.toBase64();return{targetId:t.targetId,canonicalId:Xe(t.target),readTime:e,resumeToken:i,lastListenSequenceNumber:t.sequenceNumber,lastLimboFreeSnapshotVersion:n,query:s}}function fd(r){const t=od({parent:r.parent,structuredQuery:r.structuredQuery});return r.limitType==="LAST"?Fo(t,t.limit,"L"):t}function co(r,t){return new fa(t.largestBatchId,qo(r.yt,t.overlayMutation))}function Bc(r,t){const e=t.path.lastSegment();return[r,Rt(t.path.popLast()),e]}function Uc(r,t,e,n){return{indexId:r,uid:t,sequenceNumber:e,readTime:Ze(n.readTime),documentKey:Rt(n.documentKey.path),largestBatchId:n.largestBatchId}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class i_{getBundleMetadata(t,e){return qc(t).get(e).next((n=>{if(n)return(function(i){return{id:i.bundleId,createTime:tn(i.createTime),version:i.version}})(n)}))}saveBundleMetadata(t,e){return qc(t).put((function(s){return{bundleId:s.id,createTime:Ze(Pt(s.createTime)),version:s.version}})(e))}getNamedQuery(t,e){return jc(t).get(e).next((n=>{if(n)return(function(i){return{name:i.name,query:fd(i.bundledQuery),readTime:tn(i.readTime)}})(n)}))}saveNamedQuery(t,e){return jc(t).put((function(s){return{name:s.name,readTime:Ze(Pt(s.readTime)),bundledQuery:s.bundledQuery}})(e))}}function qc(r){return _t(r,fi)}function jc(r){return _t(r,mi)}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Ti{constructor(t,e){this.serializer=t,this.userId=e}static wt(t,e){const n=e.uid||"";return new Ti(t,n)}getOverlay(t,e){return hr(t).get(Bc(this.userId,e)).next((n=>n?co(this.serializer,n):null))}getOverlays(t,e){const n=Wt();return v.forEach(e,(s=>this.getOverlay(t,s).next((i=>{i!==null&&n.set(s,i)})))).next((()=>n))}saveOverlays(t,e,n){const s=[];return n.forEach(((i,a)=>{const u=new fa(e,a);s.push(this.St(t,u))})),v.waitFor(s)}removeOverlaysForBatchId(t,e,n){const s=new Set;e.forEach((a=>s.add(Rt(a.getCollectionPath()))));const i=[];return s.forEach((a=>{const u=IDBKeyRange.bound([this.userId,a,n],[this.userId,a,n+1],!1,!0);i.push(hr(t).X(Po,u))})),v.waitFor(i)}getOverlaysForCollection(t,e,n){const s=Wt(),i=Rt(e),a=IDBKeyRange.bound([this.userId,i,n],[this.userId,i,Number.POSITIVE_INFINITY],!0);return hr(t).J(Po,a).next((u=>{for(const l of u){const d=co(this.serializer,l);s.set(d.getKey(),d)}return s}))}getOverlaysForCollectionGroup(t,e,n,s){const i=Wt();let a;const u=IDBKeyRange.bound([this.userId,e,n],[this.userId,e,Number.POSITIVE_INFINITY],!0);return hr(t).ee({index:hh,range:u},((l,d,f)=>{const g=co(this.serializer,d);i.size()<s||g.largestBatchId===a?(i.set(g.getKey(),g),a=g.largestBatchId):f.done()})).next((()=>i))}St(t,e){return hr(t).put((function(s,i,a){const[u,l,d]=Bc(i,a.mutation.key);return{userId:i,collectionPath:l,documentId:d,collectionGroup:a.mutation.key.getCollectionGroup(),largestBatchId:a.largestBatchId,overlayMutation:Ys(s.yt,a.mutation)}})(this.serializer,this.userId,e))}}function hr(r){return _t(r,gi)}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class o_{bt(t){return _t(t,ra)}getSessionToken(t){return this.bt(t).get("sessionToken").next((e=>{const n=e==null?void 0:e.value;return n?ht.fromUint8Array(n):ht.EMPTY_BYTE_STRING}))}setSessionToken(t,e){return this.bt(t).put({name:"sessionToken",value:e.toUint8Array()})}}/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ze{constructor(){}Dt(t,e){this.Ct(t,e),e.vt()}Ct(t,e){if("nullValue"in t)this.Ft(e,5);else if("booleanValue"in t)this.Ft(e,10),e.Mt(t.booleanValue?1:0);else if("integerValue"in t)this.Ft(e,15),e.Mt(it(t.integerValue));else if("doubleValue"in t){const n=it(t.doubleValue);isNaN(n)?this.Ft(e,13):(this.Ft(e,15),Mr(n)?e.Mt(0):e.Mt(n))}else if("timestampValue"in t){let n=t.timestampValue;this.Ft(e,20),typeof n=="string"&&(n=ne(n)),e.xt(`${n.seconds||""}`),e.Mt(n.nanos||0)}else if("stringValue"in t)this.Ot(t.stringValue,e),this.Nt(e);else if("bytesValue"in t)this.Ft(e,30),e.Bt(re(t.bytesValue)),this.Nt(e);else if("referenceValue"in t)this.Lt(t.referenceValue,e);else if("geoPointValue"in t){const n=t.geoPointValue;this.Ft(e,45),e.Mt(n.latitude||0),e.Mt(n.longitude||0)}else"mapValue"in t?vh(t)?this.Ft(e,Number.MAX_SAFE_INTEGER):_i(t)?this.kt(t.mapValue,e):(this.qt(t.mapValue,e),this.Nt(e)):"arrayValue"in t?(this.Kt(t.arrayValue,e),this.Nt(e)):O(19022,{Ut:t})}Ot(t,e){this.Ft(e,25),this.$t(t,e)}$t(t,e){e.xt(t)}qt(t,e){const n=t.fields||{};this.Ft(e,55);for(const s of Object.keys(n))this.Ot(s,e),this.Ct(n[s],e)}kt(t,e){var a,u;const n=t.fields||{};this.Ft(e,53);const s=Cn,i=((u=(a=n[s].arrayValue)==null?void 0:a.values)==null?void 0:u.length)||0;this.Ft(e,15),e.Mt(it(i)),this.Ot(s,e),this.Ct(n[s],e)}Kt(t,e){const n=t.values||[];this.Ft(e,50);for(const s of n)this.Ct(s,e)}Lt(t,e){this.Ft(e,37),N.fromName(t).path.forEach((n=>{this.Ft(e,60),this.$t(n,e)}))}Ft(t,e){t.Mt(e)}Nt(t){t.Mt(2)}}ze.Wt=new ze;/**
 * @license
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law | agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES | CONDITIONS OF ANY KIND, either express | implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const hn=255;function a_(r){if(r===0)return 8;let t=0;return r>>4||(t+=4,r<<=4),r>>6||(t+=2,r<<=2),r>>7||(t+=1),t}function zc(r){const t=64-(function(n){let s=0;for(let i=0;i<8;++i){const a=a_(255&n[i]);if(s+=a,a!==8)break}return s})(r);return Math.ceil(t/8)}class u_{constructor(){this.buffer=new Uint8Array(1024),this.position=0}Qt(t){const e=t[Symbol.iterator]();let n=e.next();for(;!n.done;)this.Gt(n.value),n=e.next();this.zt()}jt(t){const e=t[Symbol.iterator]();let n=e.next();for(;!n.done;)this.Jt(n.value),n=e.next();this.Ht()}Zt(t){for(const e of t){const n=e.charCodeAt(0);if(n<128)this.Gt(n);else if(n<2048)this.Gt(960|n>>>6),this.Gt(128|63&n);else if(e<"\uD800"||"\uDBFF"<e)this.Gt(480|n>>>12),this.Gt(128|63&n>>>6),this.Gt(128|63&n);else{const s=e.codePointAt(0);this.Gt(240|s>>>18),this.Gt(128|63&s>>>12),this.Gt(128|63&s>>>6),this.Gt(128|63&s)}}this.zt()}Xt(t){for(const e of t){const n=e.charCodeAt(0);if(n<128)this.Jt(n);else if(n<2048)this.Jt(960|n>>>6),this.Jt(128|63&n);else if(e<"\uD800"||"\uDBFF"<e)this.Jt(480|n>>>12),this.Jt(128|63&n>>>6),this.Jt(128|63&n);else{const s=e.codePointAt(0);this.Jt(240|s>>>18),this.Jt(128|63&s>>>12),this.Jt(128|63&s>>>6),this.Jt(128|63&s)}}this.Ht()}Yt(t){const e=this.en(t),n=zc(e);this.tn(1+n),this.buffer[this.position++]=255&n;for(let s=e.length-n;s<e.length;++s)this.buffer[this.position++]=255&e[s]}nn(t){const e=this.en(t),n=zc(e);this.tn(1+n),this.buffer[this.position++]=~(255&n);for(let s=e.length-n;s<e.length;++s)this.buffer[this.position++]=~(255&e[s])}rn(){this.sn(hn),this.sn(255)}_n(){this.an(hn),this.an(255)}reset(){this.position=0}seed(t){this.tn(t.length),this.buffer.set(t,this.position),this.position+=t.length}un(){return this.buffer.slice(0,this.position)}en(t){const e=(function(i){const a=new DataView(new ArrayBuffer(8));return a.setFloat64(0,i,!1),new Uint8Array(a.buffer)})(t),n=!!(128&e[0]);e[0]^=n?255:128;for(let s=1;s<e.length;++s)e[s]^=n?255:0;return e}Gt(t){const e=255&t;e===0?(this.sn(0),this.sn(255)):e===hn?(this.sn(hn),this.sn(0)):this.sn(e)}Jt(t){const e=255&t;e===0?(this.an(0),this.an(255)):e===hn?(this.an(hn),this.an(0)):this.an(t)}zt(){this.sn(0),this.sn(1)}Ht(){this.an(0),this.an(1)}sn(t){this.tn(1),this.buffer[this.position++]=t}an(t){this.tn(1),this.buffer[this.position++]=~t}tn(t){const e=t+this.position;if(e<=this.buffer.length)return;let n=2*this.buffer.length;n<e&&(n=e);const s=new Uint8Array(n);s.set(this.buffer),this.buffer=s}}class c_{constructor(t){this.cn=t}Bt(t){this.cn.Qt(t)}xt(t){this.cn.Zt(t)}Mt(t){this.cn.Yt(t)}vt(){this.cn.rn()}}class l_{constructor(t){this.cn=t}Bt(t){this.cn.jt(t)}xt(t){this.cn.Xt(t)}Mt(t){this.cn.nn(t)}vt(){this.cn._n()}}class dr{constructor(){this.cn=new u_,this.ascending=new c_(this.cn),this.descending=new l_(this.cn)}seed(t){this.cn.seed(t)}ln(t){return t===0?this.ascending:this.descending}un(){return this.cn.un()}reset(){this.cn.reset()}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class $e{constructor(t,e,n,s){this.hn=t,this.Pn=e,this.Tn=n,this.En=s}In(){const t=this.En.length,e=t===0||this.En[t-1]===255?t+1:t,n=new Uint8Array(e);return n.set(this.En,0),e!==t?n.set([0],this.En.length):++n[n.length-1],new $e(this.hn,this.Pn,this.Tn,n)}Rn(t,e,n){return{indexId:this.hn,uid:t,arrayValue:Fs(this.Tn),directionalValue:Fs(this.En),orderedDocumentKey:Fs(e),documentKey:n.path.toArray()}}An(t,e,n){const s=this.Rn(t,e,n);return[s.indexId,s.uid,s.arrayValue,s.directionalValue,s.orderedDocumentKey,s.documentKey]}}function de(r,t){let e=r.hn-t.hn;return e!==0?e:(e=$c(r.Tn,t.Tn),e!==0?e:(e=$c(r.En,t.En),e!==0?e:N.comparator(r.Pn,t.Pn)))}function $c(r,t){for(let e=0;e<r.length&&e<t.length;++e){const n=r[e]-t[e];if(n!==0)return n}return r.length-t.length}function Fs(r){return Ml()?(function(e){let n="";for(let s=0;s<e.length;s++)n+=String.fromCharCode(e[s]);return n})(r):r}function Gc(r){return typeof r!="string"?r:(function(e){const n=new Uint8Array(e.length);for(let s=0;s<e.length;s++)n[s]=e.charCodeAt(s);return n})(r)}class Kc{constructor(t){this.Vn=new tt(((e,n)=>ot.comparator(e.field,n.field))),this.collectionId=t.collectionGroup!=null?t.collectionGroup:t.path.lastSegment(),this.dn=t.orderBy,this.mn=[];for(const e of t.filters){const n=e;n.isInequality()?this.Vn=this.Vn.add(n):this.mn.push(n)}}get fn(){return this.Vn.size>1}gn(t){if(L(t.collectionGroup===this.collectionId,49279),this.fn)return!1;const e=Ro(t);if(e!==void 0&&!this.pn(e))return!1;const n=Be(t);let s=new Set,i=0,a=0;for(;i<n.length&&this.pn(n[i]);++i)s=s.add(n[i].fieldPath.canonicalString());if(i===n.length)return!0;if(this.Vn.size>0){const u=this.Vn.getIterator().getNext();if(!s.has(u.field.canonicalString())){const l=n[i];if(!this.yn(u,l)||!this.wn(this.dn[a++],l))return!1}++i}for(;i<n.length;++i){const u=n[i];if(a>=this.dn.length||!this.wn(this.dn[a++],u))return!1}return!0}Sn(){if(this.fn)return null;let t=new tt(ot.comparator);const e=[];for(const n of this.mn)if(!n.field.isKeyField())if(n.op==="array-contains"||n.op==="array-contains-any")e.push(new Ps(n.field,2));else{if(t.has(n.field))continue;t=t.add(n.field),e.push(new Ps(n.field,0))}for(const n of this.dn)n.field.isKeyField()||t.has(n.field)||(t=t.add(n.field),e.push(new Ps(n.field,n.dir==="asc"?0:1)));return new zs(zs.UNKNOWN_ID,this.collectionId,e,kr.empty())}pn(t){for(const e of this.mn)if(this.yn(e,t))return!0;return!1}yn(t,e){if(t===void 0||!t.field.isEqual(e.fieldPath))return!1;const n=t.op==="array-contains"||t.op==="array-contains-any";return e.kind===2===n}wn(t,e){return!!t.field.isEqual(e.fieldPath)&&(e.kind===0&&t.dir==="asc"||e.kind===1&&t.dir==="desc")}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function md(r){var e,n;if(L(r instanceof G||r instanceof Z,20012),r instanceof G){if(r instanceof xh){const s=((n=(e=r.value.arrayValue)==null?void 0:e.values)==null?void 0:n.map((i=>G.create(r.field,"==",i))))||[];return Z.create(s,"or")}return r}const t=r.filters.map((s=>md(s)));return Z.create(t,r.op)}function h_(r){if(r.getFilters().length===0)return[];const t=$o(md(r));return L(gd(t),7391),jo(t)||zo(t)?[t]:t.getFilters()}function jo(r){return r instanceof G}function zo(r){return r instanceof Z&&ua(r)}function gd(r){return jo(r)||zo(r)||(function(e){if(e instanceof Z&&No(e)){for(const n of e.getFilters())if(!jo(n)&&!zo(n))return!1;return!0}return!1})(r)}function $o(r){if(L(r instanceof G||r instanceof Z,34018),r instanceof G)return r;if(r.filters.length===1)return $o(r.filters[0]);const t=r.filters.map((n=>$o(n)));let e=Z.create(t,r.op);return e=Zs(e),gd(e)?e:(L(e instanceof Z,64498),L(Nn(e),40251),L(e.filters.length>1,57927),e.filters.reduce(((n,s)=>pa(n,s))))}function pa(r,t){let e;return L(r instanceof G||r instanceof Z,38388),L(t instanceof G||t instanceof Z,25473),e=r instanceof G?t instanceof G?(function(s,i){return Z.create([s,i],"and")})(r,t):Hc(r,t):t instanceof G?Hc(t,r):(function(s,i){if(L(s.filters.length>0&&i.filters.length>0,48005),Nn(s)&&Nn(i))return Ph(s,i.getFilters());const a=No(s)?s:i,u=No(s)?i:s,l=a.filters.map((d=>pa(d,u)));return Z.create(l,"or")})(r,t),Zs(e)}function Hc(r,t){if(Nn(t))return Ph(t,r.getFilters());{const e=t.filters.map((n=>pa(r,n)));return Z.create(e,"or")}}function Zs(r){if(L(r instanceof G||r instanceof Z,11850),r instanceof G)return r;const t=r.getFilters();if(t.length===1)return Zs(t[0]);if(Sh(r))return r;const e=t.map((s=>Zs(s))),n=[];return e.forEach((s=>{s instanceof G?n.push(s):s instanceof Z&&(s.op===r.op?n.push(...s.filters):n.push(s))})),n.length===1?n[0]:Z.create(n,r.op)}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class d_{constructor(){this.bn=new _a}addToCollectionParentIndex(t,e){return this.bn.add(e),v.resolve()}getCollectionParents(t,e){return v.resolve(this.bn.getEntries(e))}addFieldIndex(t,e){return v.resolve()}deleteFieldIndex(t,e){return v.resolve()}deleteAllFieldIndexes(t){return v.resolve()}createTargetIndexes(t,e){return v.resolve()}getDocumentsMatchingTarget(t,e){return v.resolve(null)}getIndexType(t,e){return v.resolve(0)}getFieldIndexes(t,e){return v.resolve([])}getNextCollectionGroupToUpdate(t){return v.resolve(null)}getMinOffset(t,e){return v.resolve(Ft.min())}getMinOffsetFromCollectionGroup(t,e){return v.resolve(Ft.min())}updateCollectionGroup(t,e,n){return v.resolve()}updateIndexEntries(t,e){return v.resolve()}}class _a{constructor(){this.index={}}add(t){const e=t.lastSegment(),n=t.popLast(),s=this.index[e]||new tt(Y.comparator),i=!s.has(n);return this.index[e]=s.add(n),i}has(t){const e=t.lastSegment(),n=t.popLast(),s=this.index[e];return s&&s.has(n)}getEntries(t){return(this.index[t]||new tt(Y.comparator)).toArray()}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Qc="IndexedDbIndexManager",As=new Uint8Array(0);class f_{constructor(t,e){this.databaseId=e,this.Dn=new _a,this.Cn=new se((n=>Xe(n)),((n,s)=>Wr(n,s))),this.uid=t.uid||""}addToCollectionParentIndex(t,e){if(!this.Dn.has(e)){const n=e.lastSegment(),s=e.popLast();t.addOnCommittedListener((()=>{this.Dn.add(e)}));const i={collectionId:n,parent:Rt(s)};return Wc(t).put(i)}return v.resolve()}getCollectionParents(t,e){const n=[],s=IDBKeyRange.bound([e,""],[Yl(e),""],!1,!0);return Wc(t).J(s).next((i=>{for(const a of i){if(a.collectionId!==e)break;n.push(Qt(a.parent))}return n}))}addFieldIndex(t,e){const n=fr(t),s=(function(u){return{indexId:u.indexId,collectionGroup:u.collectionGroup,fields:u.fields.map((l=>[l.fieldPath.canonicalString(),l.kind]))}})(e);delete s.indexId;const i=n.add(s);if(e.indexState){const a=fn(t);return i.next((u=>{a.put(Uc(u,this.uid,e.indexState.sequenceNumber,e.indexState.offset))}))}return i.next()}deleteFieldIndex(t,e){const n=fr(t),s=fn(t),i=dn(t);return n.delete(e.indexId).next((()=>s.delete(IDBKeyRange.bound([e.indexId],[e.indexId+1],!1,!0)))).next((()=>i.delete(IDBKeyRange.bound([e.indexId],[e.indexId+1],!1,!0))))}deleteAllFieldIndexes(t){const e=fr(t),n=dn(t),s=fn(t);return e.X().next((()=>n.X())).next((()=>s.X()))}createTargetIndexes(t,e){return v.forEach(this.vn(e),(n=>this.getIndexType(t,n).next((s=>{if(s===0||s===1){const i=new Kc(n).Sn();if(i!=null)return this.addFieldIndex(t,i)}}))))}getDocumentsMatchingTarget(t,e){const n=dn(t);let s=!0;const i=new Map;return v.forEach(this.vn(e),(a=>this.Fn(t,a).next((u=>{s&&(s=!!u),i.set(a,u)})))).next((()=>{if(s){let a=$();const u=[];return v.forEach(i,((l,d)=>{P(Qc,`Using index ${(function(q){return`id=${q.indexId}|cg=${q.collectionGroup}|f=${q.fields.map((rt=>`${rt.fieldPath}:${rt.kind}`)).join(",")}`})(l)} to execute ${Xe(e)}`);const f=(function(q,rt){const W=Ro(rt);if(W===void 0)return null;for(const J of Ws(q,W.fieldPath))switch(J.op){case"array-contains-any":return J.value.arrayValue.values||[];case"array-contains":return[J.value]}return null})(d,l),g=(function(q,rt){const W=new Map;for(const J of Be(rt))for(const I of Ws(q,J.fieldPath))switch(I.op){case"==":case"in":W.set(J.fieldPath.canonicalString(),I.value);break;case"not-in":case"!=":return W.set(J.fieldPath.canonicalString(),I.value),Array.from(W.values())}return null})(d,l),E=(function(q,rt){const W=[];let J=!0;for(const I of Be(rt)){const p=I.kind===0?Rc(q,I.fieldPath,q.startAt):Sc(q,I.fieldPath,q.startAt);W.push(p.value),J&&(J=p.inclusive)}return new xn(W,J)})(d,l),V=(function(q,rt){const W=[];let J=!0;for(const I of Be(rt)){const p=I.kind===0?Sc(q,I.fieldPath,q.endAt):Rc(q,I.fieldPath,q.endAt);W.push(p.value),J&&(J=p.inclusive)}return new xn(W,J)})(d,l),D=this.Mn(l,d,E),k=this.Mn(l,d,V),M=this.xn(l,d,g),K=this.On(l.indexId,f,D,E.inclusive,k,V.inclusive,M);return v.forEach(K,(j=>n.Z(j,e.limit).next((q=>{q.forEach((rt=>{const W=N.fromSegments(rt.documentKey);a.has(W)||(a=a.add(W),u.push(W))}))}))))})).next((()=>u))}return v.resolve(null)}))}vn(t){let e=this.Cn.get(t);return e||(t.filters.length===0?e=[t]:e=h_(Z.create(t.filters,"and")).map((n=>Mo(t.path,t.collectionGroup,t.orderBy,n.getFilters(),t.limit,t.startAt,t.endAt))),this.Cn.set(t,e),e)}On(t,e,n,s,i,a,u){const l=(e!=null?e.length:1)*Math.max(n.length,i.length),d=l/(e!=null?e.length:1),f=[];for(let g=0;g<l;++g){const E=e?this.Nn(e[g/d]):As,V=this.Bn(t,E,n[g%d],s),D=this.Ln(t,E,i[g%d],a),k=u.map((M=>this.Bn(t,E,M,!0)));f.push(...this.createRange(V,D,k))}return f}Bn(t,e,n,s){const i=new $e(t,N.empty(),e,n);return s?i:i.In()}Ln(t,e,n,s){const i=new $e(t,N.empty(),e,n);return s?i.In():i}Fn(t,e){const n=new Kc(e),s=e.collectionGroup!=null?e.collectionGroup:e.path.lastSegment();return this.getFieldIndexes(t,s).next((i=>{let a=null;for(const u of i)n.gn(u)&&(!a||u.fields.length>a.fields.length)&&(a=u);return a}))}getIndexType(t,e){let n=2;const s=this.vn(e);return v.forEach(s,(i=>this.Fn(t,i).next((a=>{a?n!==0&&a.fields.length<(function(l){let d=new tt(ot.comparator),f=!1;for(const g of l.filters)for(const E of g.getFlattenedFilters())E.field.isKeyField()||(E.op==="array-contains"||E.op==="array-contains-any"?f=!0:d=d.add(E.field));for(const g of l.orderBy)g.field.isKeyField()||(d=d.add(g.field));return d.size+(f?1:0)})(i)&&(n=1):n=0})))).next((()=>(function(a){return a.limit!==null})(e)&&s.length>1&&n===2?1:n))}kn(t,e){const n=new dr;for(const s of Be(t)){const i=e.data.field(s.fieldPath);if(i==null)return null;const a=n.ln(s.kind);ze.Wt.Dt(i,a)}return n.un()}Nn(t){const e=new dr;return ze.Wt.Dt(t,e.ln(0)),e.un()}qn(t,e){const n=new dr;return ze.Wt.Dt(qr(this.databaseId,e),n.ln((function(i){const a=Be(i);return a.length===0?0:a[a.length-1].kind})(t))),n.un()}xn(t,e,n){if(n===null)return[];let s=[];s.push(new dr);let i=0;for(const a of Be(t)){const u=n[i++];for(const l of s)if(this.Kn(e,a.fieldPath)&&jr(u))s=this.Un(s,a,u);else{const d=l.ln(a.kind);ze.Wt.Dt(u,d)}}return this.$n(s)}Mn(t,e,n){return this.xn(t,e,n.position)}$n(t){const e=[];for(let n=0;n<t.length;++n)e[n]=t[n].un();return e}Un(t,e,n){const s=[...t],i=[];for(const a of n.arrayValue.values||[])for(const u of s){const l=new dr;l.seed(u.un()),ze.Wt.Dt(a,l.ln(e.kind)),i.push(l)}return i}Kn(t,e){return!!t.filters.find((n=>n instanceof G&&n.field.isEqual(e)&&(n.op==="in"||n.op==="not-in")))}getFieldIndexes(t,e){const n=fr(t),s=fn(t);return(e?n.J(Vo,IDBKeyRange.bound(e,e)):n.J()).next((i=>{const a=[];return v.forEach(i,(u=>s.get([u.indexId,this.uid]).next((l=>{a.push((function(f,g){const E=g?new kr(g.sequenceNumber,new Ft(tn(g.readTime),new N(Qt(g.documentKey)),g.largestBatchId)):kr.empty(),V=f.fields.map((([D,k])=>new Ps(ot.fromServerFormat(D),k)));return new zs(f.indexId,f.collectionGroup,V,E)})(u,l))})))).next((()=>a))}))}getNextCollectionGroupToUpdate(t){return this.getFieldIndexes(t).next((e=>e.length===0?null:(e.sort(((n,s)=>{const i=n.indexState.sequenceNumber-s.indexState.sequenceNumber;return i!==0?i:U(n.collectionGroup,s.collectionGroup)})),e[0].collectionGroup)))}updateCollectionGroup(t,e,n){const s=fr(t),i=fn(t);return this.Wn(t).next((a=>s.J(Vo,IDBKeyRange.bound(e,e)).next((u=>v.forEach(u,(l=>i.put(Uc(l.indexId,this.uid,a,n))))))))}updateIndexEntries(t,e){const n=new Map;return v.forEach(e,((s,i)=>{const a=n.get(s.collectionGroup);return(a?v.resolve(a):this.getFieldIndexes(t,s.collectionGroup)).next((u=>(n.set(s.collectionGroup,u),v.forEach(u,(l=>this.Qn(t,s,l).next((d=>{const f=this.Gn(i,l);return d.isEqual(f)?v.resolve():this.zn(t,i,l,d,f)})))))))}))}jn(t,e,n,s){return dn(t).put(s.Rn(this.uid,this.qn(n,e.key),e.key))}Jn(t,e,n,s){return dn(t).delete(s.An(this.uid,this.qn(n,e.key),e.key))}Qn(t,e,n){const s=dn(t);let i=new tt(de);return s.ee({index:lh,range:IDBKeyRange.only([n.indexId,this.uid,Fs(this.qn(n,e))])},((a,u)=>{i=i.add(new $e(n.indexId,e,Gc(u.arrayValue),Gc(u.directionalValue)))})).next((()=>i))}Gn(t,e){let n=new tt(de);const s=this.kn(e,t);if(s==null)return n;const i=Ro(e);if(i!=null){const a=t.data.field(i.fieldPath);if(jr(a))for(const u of a.arrayValue.values||[])n=n.add(new $e(e.indexId,t.key,this.Nn(u),s))}else n=n.add(new $e(e.indexId,t.key,As,s));return n}zn(t,e,n,s,i){P(Qc,"Updating index entries for document '%s'",e.key);const a=[];return(function(l,d,f,g,E){const V=l.getIterator(),D=d.getIterator();let k=ln(V),M=ln(D);for(;k||M;){let K=!1,j=!1;if(k&&M){const q=f(k,M);q<0?j=!0:q>0&&(K=!0)}else k!=null?j=!0:K=!0;K?(g(M),M=ln(D)):j?(E(k),k=ln(V)):(k=ln(V),M=ln(D))}})(s,i,de,(u=>{a.push(this.jn(t,e,n,u))}),(u=>{a.push(this.Jn(t,e,n,u))})),v.waitFor(a)}Wn(t){let e=1;return fn(t).ee({index:ch,reverse:!0,range:IDBKeyRange.upperBound([this.uid,Number.MAX_SAFE_INTEGER])},((n,s,i)=>{i.done(),e=s.sequenceNumber+1})).next((()=>e))}createRange(t,e,n){n=n.sort(((a,u)=>de(a,u))).filter(((a,u,l)=>!u||de(a,l[u-1])!==0));const s=[];s.push(t);for(const a of n){const u=de(a,t),l=de(a,e);if(u===0)s[0]=t.In();else if(u>0&&l<0)s.push(a),s.push(a.In());else if(l>0)break}s.push(e);const i=[];for(let a=0;a<s.length;a+=2){if(this.Hn(s[a],s[a+1]))return[];const u=s[a].An(this.uid,As,N.empty()),l=s[a+1].An(this.uid,As,N.empty());i.push(IDBKeyRange.bound(u,l))}return i}Hn(t,e){return de(t,e)>0}getMinOffsetFromCollectionGroup(t,e){return this.getFieldIndexes(t,e).next(Jc)}getMinOffset(t,e){return v.mapArray(this.vn(e),(n=>this.Fn(t,n).next((s=>s||O(44426))))).next(Jc)}}function Wc(r){return _t(r,Lr)}function dn(r){return _t(r,Rr)}function fr(r){return _t(r,na)}function fn(r){return _t(r,br)}function Jc(r){L(r.length!==0,28825);let t=r[0].indexState.offset,e=t.largestBatchId;for(let n=1;n<r.length;n++){const s=r[n].indexState.offset;Zo(s,t)<0&&(t=s),e<s.largestBatchId&&(e=s.largestBatchId)}return new Ft(t.readTime,t.documentKey,e)}/**
 * @license
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Yc={didRun:!1,sequenceNumbersCollected:0,targetsRemoved:0,documentsRemoved:0},pd=41943040;class At{static withCacheSize(t){return new At(t,At.DEFAULT_COLLECTION_PERCENTILE,At.DEFAULT_MAX_SEQUENCE_NUMBERS_TO_COLLECT)}constructor(t,e,n){this.cacheSizeCollectionThreshold=t,this.percentileToCollect=e,this.maximumSequenceNumbersToCollect=n}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function _d(r,t,e){const n=r.store(qt),s=r.store(Rn),i=[],a=IDBKeyRange.only(e.batchId);let u=0;const l=n.ee({range:a},((f,g,E)=>(u++,E.delete())));i.push(l.next((()=>{L(u===1,47070,{batchId:e.batchId})})));const d=[];for(const f of e.mutations){const g=oh(t,f.key.path,e.batchId);i.push(s.delete(g)),d.push(f.key)}return v.waitFor(i).next((()=>d))}function ti(r){if(!r)return 0;let t;if(r.document)t=r.document;else if(r.unknownDocument)t=r.unknownDocument;else{if(!r.noDocument)throw O(14731);t=r.noDocument}return JSON.stringify(t).length}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */At.DEFAULT_COLLECTION_PERCENTILE=10,At.DEFAULT_MAX_SEQUENCE_NUMBERS_TO_COLLECT=1e3,At.DEFAULT=new At(pd,At.DEFAULT_COLLECTION_PERCENTILE,At.DEFAULT_MAX_SEQUENCE_NUMBERS_TO_COLLECT),At.DISABLED=new At(-1,0,0);class wi{constructor(t,e,n,s){this.userId=t,this.serializer=e,this.indexManager=n,this.referenceDelegate=s,this.Zn={}}static wt(t,e,n,s){L(t.uid!=="",64387);const i=t.isAuthenticated()?t.uid:"";return new wi(i,e,n,s)}checkEmpty(t){let e=!0;const n=IDBKeyRange.bound([this.userId,Number.NEGATIVE_INFINITY],[this.userId,Number.POSITIVE_INFINITY]);return fe(t).ee({index:Ge,range:n},((s,i,a)=>{e=!1,a.done()})).next((()=>e))}addMutationBatch(t,e,n,s){const i=In(t),a=fe(t);return a.add({}).next((u=>{L(typeof u=="number",49019);const l=new ha(u,e,n,s),d=(function(V,D,k){const M=k.baseMutations.map((j=>Ys(V.yt,j))),K=k.mutations.map((j=>Ys(V.yt,j)));return{userId:D,batchId:k.batchId,localWriteTimeMs:k.localWriteTime.toMillis(),baseMutations:M,mutations:K}})(this.serializer,this.userId,l),f=[];let g=new tt(((E,V)=>U(E.canonicalString(),V.canonicalString())));for(const E of s){const V=oh(this.userId,E.key.path,u);g=g.add(E.key.path.popLast()),f.push(a.put(d)),f.push(i.put(V,jg))}return g.forEach((E=>{f.push(this.indexManager.addToCollectionParentIndex(t,E))})),t.addOnCommittedListener((()=>{this.Zn[u]=l.keys()})),v.waitFor(f).next((()=>l))}))}lookupMutationBatch(t,e){return fe(t).get(e).next((n=>n?(L(n.userId===this.userId,48,"Unexpected user for mutation batch",{userId:n.userId,batchId:e}),je(this.serializer,n)):null))}Xn(t,e){return this.Zn[e]?v.resolve(this.Zn[e]):this.lookupMutationBatch(t,e).next((n=>{if(n){const s=n.keys();return this.Zn[e]=s,s}return null}))}getNextMutationBatchAfterBatchId(t,e){const n=e+1,s=IDBKeyRange.lowerBound([this.userId,n]);let i=null;return fe(t).ee({index:Ge,range:s},((a,u,l)=>{u.userId===this.userId&&(L(u.batchId>=n,47524,{Yn:n}),i=je(this.serializer,u)),l.done()})).next((()=>i))}getHighestUnacknowledgedBatchId(t){const e=IDBKeyRange.upperBound([this.userId,Number.POSITIVE_INFINITY]);let n=Ke;return fe(t).ee({index:Ge,range:e,reverse:!0},((s,i,a)=>{n=i.batchId,a.done()})).next((()=>n))}getAllMutationBatches(t){const e=IDBKeyRange.bound([this.userId,Ke],[this.userId,Number.POSITIVE_INFINITY]);return fe(t).J(Ge,e).next((n=>n.map((s=>je(this.serializer,s)))))}getAllMutationBatchesAffectingDocumentKey(t,e){const n=Cs(this.userId,e.path),s=IDBKeyRange.lowerBound(n),i=[];return In(t).ee({range:s},((a,u,l)=>{const[d,f,g]=a,E=Qt(f);if(d===this.userId&&e.path.isEqual(E))return fe(t).get(g).next((V=>{if(!V)throw O(61480,{er:a,batchId:g});L(V.userId===this.userId,10503,"Unexpected user for mutation batch",{userId:V.userId,batchId:g}),i.push(je(this.serializer,V))}));l.done()})).next((()=>i))}getAllMutationBatchesAffectingDocumentKeys(t,e){let n=new tt(U);const s=[];return e.forEach((i=>{const a=Cs(this.userId,i.path),u=IDBKeyRange.lowerBound(a),l=In(t).ee({range:u},((d,f,g)=>{const[E,V,D]=d,k=Qt(V);E===this.userId&&i.path.isEqual(k)?n=n.add(D):g.done()}));s.push(l)})),v.waitFor(s).next((()=>this.tr(t,n)))}getAllMutationBatchesAffectingQuery(t,e){const n=e.path,s=n.length+1,i=Cs(this.userId,n),a=IDBKeyRange.lowerBound(i);let u=new tt(U);return In(t).ee({range:a},((l,d,f)=>{const[g,E,V]=l,D=Qt(E);g===this.userId&&n.isPrefixOf(D)?D.length===s&&(u=u.add(V)):f.done()})).next((()=>this.tr(t,u)))}tr(t,e){const n=[],s=[];return e.forEach((i=>{s.push(fe(t).get(i).next((a=>{if(a===null)throw O(35274,{batchId:i});L(a.userId===this.userId,9748,"Unexpected user for mutation batch",{userId:a.userId,batchId:i}),n.push(je(this.serializer,a))})))})),v.waitFor(s).next((()=>n))}removeMutationBatch(t,e){return _d(t.le,this.userId,e).next((n=>(t.addOnCommittedListener((()=>{this.nr(e.batchId)})),v.forEach(n,(s=>this.referenceDelegate.markPotentiallyOrphaned(t,s))))))}nr(t){delete this.Zn[t]}performConsistencyCheck(t){return this.checkEmpty(t).next((e=>{if(!e)return v.resolve();const n=IDBKeyRange.lowerBound((function(a){return[a]})(this.userId)),s=[];return In(t).ee({range:n},((i,a,u)=>{if(i[0]===this.userId){const l=Qt(i[1]);s.push(l)}else u.done()})).next((()=>{L(s.length===0,56720,{rr:s.map((i=>i.canonicalString()))})}))}))}containsKey(t,e){return yd(t,this.userId,e)}ir(t){return Id(t).get(this.userId).next((e=>e||{userId:this.userId,lastAcknowledgedBatchId:Ke,lastStreamToken:""}))}}function yd(r,t,e){const n=Cs(t,e.path),s=n[1],i=IDBKeyRange.lowerBound(n);let a=!1;return In(r).ee({range:i,Y:!0},((u,l,d)=>{const[f,g,E]=u;f===t&&g===s&&(a=!0),d.done()})).next((()=>a))}function fe(r){return _t(r,qt)}function In(r){return _t(r,Rn)}function Id(r){return _t(r,Or)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class en{constructor(t){this.sr=t}next(){return this.sr+=2,this.sr}static _r(){return new en(0)}static ar(){return new en(-1)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class m_{constructor(t,e){this.referenceDelegate=t,this.serializer=e}allocateTargetId(t){return this.ur(t).next((e=>{const n=new en(e.highestTargetId);return e.highestTargetId=n.next(),this.cr(t,e).next((()=>e.highestTargetId))}))}getLastRemoteSnapshotVersion(t){return this.ur(t).next((e=>B.fromTimestamp(new X(e.lastRemoteSnapshotVersion.seconds,e.lastRemoteSnapshotVersion.nanoseconds))))}getHighestSequenceNumber(t){return this.ur(t).next((e=>e.highestListenSequenceNumber))}setTargetsMetadata(t,e,n){return this.ur(t).next((s=>(s.highestListenSequenceNumber=e,n&&(s.lastRemoteSnapshotVersion=n.toTimestamp()),e>s.highestListenSequenceNumber&&(s.highestListenSequenceNumber=e),this.cr(t,s))))}addTargetData(t,e){return this.lr(t,e).next((()=>this.ur(t).next((n=>(n.targetCount+=1,this.hr(e,n),this.cr(t,n))))))}updateTargetData(t,e){return this.lr(t,e)}removeTargetData(t,e){return this.removeMatchingKeysForTargetId(t,e.targetId).next((()=>mn(t).delete(e.targetId))).next((()=>this.ur(t))).next((n=>(L(n.targetCount>0,8065),n.targetCount-=1,this.cr(t,n))))}removeTargets(t,e,n){let s=0;const i=[];return mn(t).ee(((a,u)=>{const l=Er(u);l.sequenceNumber<=e&&n.get(l.targetId)===null&&(s++,i.push(this.removeTargetData(t,l)))})).next((()=>v.waitFor(i))).next((()=>s))}forEachTarget(t,e){return mn(t).ee(((n,s)=>{const i=Er(s);e(i)}))}ur(t){return Xc(t).get(Ks).next((e=>(L(e!==null,2888),e)))}cr(t,e){return Xc(t).put(Ks,e)}lr(t,e){return mn(t).put(dd(this.serializer,e))}hr(t,e){let n=!1;return t.targetId>e.highestTargetId&&(e.highestTargetId=t.targetId,n=!0),t.sequenceNumber>e.highestListenSequenceNumber&&(e.highestListenSequenceNumber=t.sequenceNumber,n=!0),n}getTargetCount(t){return this.ur(t).next((e=>e.targetCount))}getTargetData(t,e){const n=Xe(e),s=IDBKeyRange.bound([n,Number.NEGATIVE_INFINITY],[n,Number.POSITIVE_INFINITY]);let i=null;return mn(t).ee({range:s,index:uh},((a,u,l)=>{const d=Er(u);Wr(e,d.target)&&(i=d,l.done())})).next((()=>i))}addMatchingKeys(t,e,n){const s=[],i=ge(t);return e.forEach((a=>{const u=Rt(a.path);s.push(i.put({targetId:n,path:u})),s.push(this.referenceDelegate.addReference(t,n,a))})),v.waitFor(s)}removeMatchingKeys(t,e,n){const s=ge(t);return v.forEach(e,(i=>{const a=Rt(i.path);return v.waitFor([s.delete([n,a]),this.referenceDelegate.removeReference(t,n,i)])}))}removeMatchingKeysForTargetId(t,e){const n=ge(t),s=IDBKeyRange.bound([e],[e+1],!1,!0);return n.delete(s)}getMatchingKeysForTargetId(t,e){const n=IDBKeyRange.bound([e],[e+1],!1,!0),s=ge(t);let i=$();return s.ee({range:n,Y:!0},((a,u,l)=>{const d=Qt(a[1]),f=new N(d);i=i.add(f)})).next((()=>i))}containsKey(t,e){const n=Rt(e.path),s=IDBKeyRange.bound([n],[Yl(n)],!1,!0);let i=0;return ge(t).ee({index:ea,Y:!0,range:s},(([a,u],l,d)=>{a!==0&&(i++,d.done())})).next((()=>i>0))}At(t,e){return mn(t).get(e).next((n=>n?Er(n):null))}}function mn(r){return _t(r,Sn)}function Xc(r){return _t(r,He)}function ge(r){return _t(r,Vn)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Zc="LruGarbageCollector",Ed=1048576;function tl([r,t],[e,n]){const s=U(r,e);return s===0?U(t,n):s}class g_{constructor(t){this.Pr=t,this.buffer=new tt(tl),this.Tr=0}Er(){return++this.Tr}Ir(t){const e=[t,this.Er()];if(this.buffer.size<this.Pr)this.buffer=this.buffer.add(e);else{const n=this.buffer.last();tl(e,n)<0&&(this.buffer=this.buffer.delete(n).add(e))}}get maxValue(){return this.buffer.last()[0]}}class Td{constructor(t,e,n){this.garbageCollector=t,this.asyncQueue=e,this.localStore=n,this.Rr=null}start(){this.garbageCollector.params.cacheSizeCollectionThreshold!==-1&&this.Ar(6e4)}stop(){this.Rr&&(this.Rr.cancel(),this.Rr=null)}get started(){return this.Rr!==null}Ar(t){P(Zc,`Garbage collection scheduled in ${t}ms`),this.Rr=this.asyncQueue.enqueueAfterDelay("lru_garbage_collection",t,(async()=>{this.Rr=null;try{await this.localStore.collectGarbage(this.garbageCollector)}catch(e){Se(e)?P(Zc,"Ignoring IndexedDB error during garbage collection: ",e):await Re(e)}await this.Ar(3e5)}))}}class p_{constructor(t,e){this.Vr=t,this.params=e}calculateTargetCount(t,e){return this.Vr.dr(t).next((n=>Math.floor(e/100*n)))}nthSequenceNumber(t,e){if(e===0)return v.resolve(Dt.ce);const n=new g_(e);return this.Vr.forEachTarget(t,(s=>n.Ir(s.sequenceNumber))).next((()=>this.Vr.mr(t,(s=>n.Ir(s))))).next((()=>n.maxValue))}removeTargets(t,e,n){return this.Vr.removeTargets(t,e,n)}removeOrphanedDocuments(t,e){return this.Vr.removeOrphanedDocuments(t,e)}collect(t,e){return this.params.cacheSizeCollectionThreshold===-1?(P("LruGarbageCollector","Garbage collection skipped; disabled"),v.resolve(Yc)):this.getCacheSize(t).next((n=>n<this.params.cacheSizeCollectionThreshold?(P("LruGarbageCollector",`Garbage collection skipped; Cache size ${n} is lower than threshold ${this.params.cacheSizeCollectionThreshold}`),Yc):this.gr(t,e)))}getCacheSize(t){return this.Vr.getCacheSize(t)}gr(t,e){let n,s,i,a,u,l,d;const f=Date.now();return this.calculateTargetCount(t,this.params.percentileToCollect).next((g=>(g>this.params.maximumSequenceNumbersToCollect?(P("LruGarbageCollector",`Capping sequence numbers to collect down to the maximum of ${this.params.maximumSequenceNumbersToCollect} from ${g}`),s=this.params.maximumSequenceNumbersToCollect):s=g,a=Date.now(),this.nthSequenceNumber(t,s)))).next((g=>(n=g,u=Date.now(),this.removeTargets(t,n,e)))).next((g=>(i=g,l=Date.now(),this.removeOrphanedDocuments(t,n)))).next((g=>(d=Date.now(),gn()<=Q.DEBUG&&P("LruGarbageCollector",`LRU Garbage Collection
	Counted targets in ${a-f}ms
	Determined least recently used ${s} in `+(u-a)+`ms
	Removed ${i} targets in `+(l-u)+`ms
	Removed ${g} documents in `+(d-l)+`ms
Total Duration: ${d-f}ms`),v.resolve({didRun:!0,sequenceNumbersCollected:s,targetsRemoved:i,documentsRemoved:g}))))}}function wd(r,t){return new p_(r,t)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class __{constructor(t,e){this.db=t,this.garbageCollector=wd(this,e)}dr(t){const e=this.pr(t);return this.db.getTargetCache().getTargetCount(t).next((n=>e.next((s=>n+s))))}pr(t){let e=0;return this.mr(t,(n=>{e++})).next((()=>e))}forEachTarget(t,e){return this.db.getTargetCache().forEachTarget(t,e)}mr(t,e){return this.yr(t,((n,s)=>e(s)))}addReference(t,e,n){return bs(t,n)}removeReference(t,e,n){return bs(t,n)}removeTargets(t,e,n){return this.db.getTargetCache().removeTargets(t,e,n)}markPotentiallyOrphaned(t,e){return bs(t,e)}wr(t,e){return(function(s,i){let a=!1;return Id(s).te((u=>yd(s,u,i).next((l=>(l&&(a=!0),v.resolve(!l)))))).next((()=>a))})(t,e)}removeOrphanedDocuments(t,e){const n=this.db.getRemoteDocumentCache().newChangeBuffer(),s=[];let i=0;return this.yr(t,((a,u)=>{if(u<=e){const l=this.wr(t,a).next((d=>{if(!d)return i++,n.getEntry(t,a).next((()=>(n.removeEntry(a,B.min()),ge(t).delete((function(g){return[0,Rt(g.path)]})(a)))))}));s.push(l)}})).next((()=>v.waitFor(s))).next((()=>n.apply(t))).next((()=>i))}removeTarget(t,e){const n=e.withSequenceNumber(t.currentSequenceNumber);return this.db.getTargetCache().updateTargetData(t,n)}updateLimboDocument(t,e){return bs(t,e)}yr(t,e){const n=ge(t);let s,i=Dt.ce;return n.ee({index:ea},(([a,u],{path:l,sequenceNumber:d})=>{a===0?(i!==Dt.ce&&e(new N(Qt(s)),i),i=d,s=l):i=Dt.ce})).next((()=>{i!==Dt.ce&&e(new N(Qt(s)),i)}))}getCacheSize(t){return this.db.getRemoteDocumentCache().getSize(t)}}function bs(r,t){return ge(r).put((function(n,s){return{targetId:0,path:Rt(n.path),sequenceNumber:s}})(t,r.currentSequenceNumber))}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class vd{constructor(){this.changes=new se((t=>t.toString()),((t,e)=>t.isEqual(e))),this.changesApplied=!1}addEntry(t){this.assertNotApplied(),this.changes.set(t.key,t)}removeEntry(t,e){this.assertNotApplied(),this.changes.set(t,ct.newInvalidDocument(t).setReadTime(e))}getEntry(t,e){this.assertNotApplied();const n=this.changes.get(e);return n!==void 0?v.resolve(n):this.getFromCache(t,e)}getEntries(t,e){return this.getAllFromCache(t,e)}apply(t){return this.assertNotApplied(),this.changesApplied=!0,this.applyChanges(t)}assertNotApplied(){}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class y_{constructor(t){this.serializer=t}setIndexManager(t){this.indexManager=t}addEntry(t,e,n){return Fe(t).put(n)}removeEntry(t,e,n){return Fe(t).delete((function(i,a){const u=i.path.toArray();return[u.slice(0,u.length-2),u[u.length-2],Xs(a),u[u.length-1]]})(e,n))}updateMetadata(t,e){return this.getMetadata(t).next((n=>(n.byteSize+=e,this.Sr(t,n))))}getEntry(t,e){let n=ct.newInvalidDocument(e);return Fe(t).ee({index:Ds,range:IDBKeyRange.only(mr(e))},((s,i)=>{n=this.br(e,i)})).next((()=>n))}Dr(t,e){let n={size:0,document:ct.newInvalidDocument(e)};return Fe(t).ee({index:Ds,range:IDBKeyRange.only(mr(e))},((s,i)=>{n={document:this.br(e,i),size:ti(i)}})).next((()=>n))}getEntries(t,e){let n=Mt();return this.Cr(t,e,((s,i)=>{const a=this.br(s,i);n=n.insert(s,a)})).next((()=>n))}vr(t,e){let n=Mt(),s=new nt(N.comparator);return this.Cr(t,e,((i,a)=>{const u=this.br(i,a);n=n.insert(i,u),s=s.insert(i,ti(a))})).next((()=>({documents:n,Fr:s})))}Cr(t,e,n){if(e.isEmpty())return v.resolve();let s=new tt(rl);e.forEach((l=>s=s.add(l)));const i=IDBKeyRange.bound(mr(s.first()),mr(s.last())),a=s.getIterator();let u=a.getNext();return Fe(t).ee({index:Ds,range:i},((l,d,f)=>{const g=N.fromSegments([...d.prefixPath,d.collectionGroup,d.documentId]);for(;u&&rl(u,g)<0;)n(u,null),u=a.getNext();u&&u.isEqual(g)&&(n(u,d),u=a.hasNext()?a.getNext():null),u?f.j(mr(u)):f.done()})).next((()=>{for(;u;)n(u,null),u=a.hasNext()?a.getNext():null}))}getDocumentsMatchingQuery(t,e,n,s,i){const a=e.path,u=[a.popLast().toArray(),a.lastSegment(),Xs(n.readTime),n.documentKey.path.isEmpty()?"":n.documentKey.path.lastSegment()],l=[a.popLast().toArray(),a.lastSegment(),[Number.MAX_SAFE_INTEGER,Number.MAX_SAFE_INTEGER],""];return Fe(t).J(IDBKeyRange.bound(u,l,!0)).next((d=>{i==null||i.incrementDocumentReadCount(d.length);let f=Mt();for(const g of d){const E=this.br(N.fromSegments(g.prefixPath.concat(g.collectionGroup,g.documentId)),g);E.isFoundDocument()&&(Yr(e,E)||s.has(E.key))&&(f=f.insert(E.key,E))}return f}))}getAllFromCollectionGroup(t,e,n,s){let i=Mt();const a=nl(e,n),u=nl(e,Ft.max());return Fe(t).ee({index:ah,range:IDBKeyRange.bound(a,u,!0)},((l,d,f)=>{const g=this.br(N.fromSegments(d.prefixPath.concat(d.collectionGroup,d.documentId)),d);i=i.insert(g.key,g),i.size===s&&f.done()})).next((()=>i))}newChangeBuffer(t){return new I_(this,!!t&&t.trackRemovals)}getSize(t){return this.getMetadata(t).next((e=>e.byteSize))}getMetadata(t){return el(t).get(So).next((e=>(L(!!e,20021),e)))}Sr(t,e){return el(t).put(So,e)}br(t,e){if(e){const n=s_(this.serializer,e);if(!(n.isNoDocument()&&n.version.isEqual(B.min())))return n}return ct.newInvalidDocument(t)}}function Ad(r){return new y_(r)}class I_ extends vd{constructor(t,e){super(),this.Mr=t,this.trackRemovals=e,this.Or=new se((n=>n.toString()),((n,s)=>n.isEqual(s)))}applyChanges(t){const e=[];let n=0,s=new tt(((i,a)=>U(i.canonicalString(),a.canonicalString())));return this.changes.forEach(((i,a)=>{const u=this.Or.get(i);if(e.push(this.Mr.removeEntry(t,i,u.readTime)),a.isValidDocument()){const l=Lc(this.Mr.serializer,a);s=s.add(i.path.popLast());const d=ti(l);n+=d-u.size,e.push(this.Mr.addEntry(t,i,l))}else if(n-=u.size,this.trackRemovals){const l=Lc(this.Mr.serializer,a.convertToNoDocument(B.min()));e.push(this.Mr.addEntry(t,i,l))}})),s.forEach((i=>{e.push(this.Mr.indexManager.addToCollectionParentIndex(t,i))})),e.push(this.Mr.updateMetadata(t,n)),v.waitFor(e)}getFromCache(t,e){return this.Mr.Dr(t,e).next((n=>(this.Or.set(e,{size:n.size,readTime:n.document.readTime}),n.document)))}getAllFromCache(t,e){return this.Mr.vr(t,e).next((({documents:n,Fr:s})=>(s.forEach(((i,a)=>{this.Or.set(i,{size:a,readTime:n.get(i).readTime})})),n)))}}function el(r){return _t(r,Fr)}function Fe(r){return _t(r,Gs)}function mr(r){const t=r.path.toArray();return[t.slice(0,t.length-2),t[t.length-2],t[t.length-1]]}function nl(r,t){const e=t.documentKey.path.toArray();return[r,Xs(t.readTime),e.slice(0,e.length-2),e.length>0?e[e.length-1]:""]}function rl(r,t){const e=r.path.toArray(),n=t.path.toArray();let s=0;for(let i=0;i<e.length-2&&i<n.length-2;++i)if(s=U(e[i],n[i]),s)return s;return s=U(e.length,n.length),s||(s=U(e[e.length-2],n[n.length-2]),s||U(e[e.length-1],n[n.length-1]))}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *//**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class E_{constructor(t,e){this.overlayedDocument=t,this.mutatedFields=e}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class bd{constructor(t,e,n,s){this.remoteDocumentCache=t,this.mutationQueue=e,this.documentOverlayCache=n,this.indexManager=s}getDocument(t,e){let n=null;return this.documentOverlayCache.getOverlay(t,e).next((s=>(n=s,this.remoteDocumentCache.getEntry(t,e)))).next((s=>(n!==null&&Cr(n.mutation,s,xt.empty(),X.now()),s)))}getDocuments(t,e){return this.remoteDocumentCache.getEntries(t,e).next((n=>this.getLocalViewOfDocuments(t,n,$()).next((()=>n))))}getLocalViewOfDocuments(t,e,n=$()){const s=Wt();return this.populateOverlays(t,s,e).next((()=>this.computeViews(t,e,s,n).next((i=>{let a=yr();return i.forEach(((u,l)=>{a=a.insert(u,l.overlayedDocument)})),a}))))}getOverlayedDocuments(t,e){const n=Wt();return this.populateOverlays(t,n,e).next((()=>this.computeViews(t,e,n,$())))}populateOverlays(t,e,n){const s=[];return n.forEach((i=>{e.has(i)||s.push(i)})),this.documentOverlayCache.getOverlays(t,s).next((i=>{i.forEach(((a,u)=>{e.set(a,u)}))}))}computeViews(t,e,n,s){let i=Mt();const a=Pr(),u=(function(){return Pr()})();return e.forEach(((l,d)=>{const f=n.get(d.key);s.has(d.key)&&(f===void 0||f.mutation instanceof ie)?i=i.insert(d.key,d):f!==void 0?(a.set(d.key,f.mutation.getFieldMask()),Cr(f.mutation,d,f.mutation.getFieldMask(),X.now())):a.set(d.key,xt.empty())})),this.recalculateAndSaveOverlays(t,i).next((l=>(l.forEach(((d,f)=>a.set(d,f))),e.forEach(((d,f)=>u.set(d,new E_(f,a.get(d)??null)))),u)))}recalculateAndSaveOverlays(t,e){const n=Pr();let s=new nt(((a,u)=>a-u)),i=$();return this.mutationQueue.getAllMutationBatchesAffectingDocumentKeys(t,e).next((a=>{for(const u of a)u.keys().forEach((l=>{const d=e.get(l);if(d===null)return;let f=n.get(l)||xt.empty();f=u.applyToLocalView(d,f),n.set(l,f);const g=(s.get(u.batchId)||$()).add(l);s=s.insert(u.batchId,g)}))})).next((()=>{const a=[],u=s.getReverseIterator();for(;u.hasNext();){const l=u.getNext(),d=l.key,f=l.value,g=Uh();f.forEach((E=>{if(!i.has(E)){const V=Hh(e.get(E),n.get(E));V!==null&&g.set(E,V),i=i.add(E)}})),a.push(this.documentOverlayCache.saveOverlays(t,d,g))}return v.waitFor(a)})).next((()=>n))}recalculateAndSaveOverlaysForDocumentKeys(t,e){return this.remoteDocumentCache.getEntries(t,e).next((n=>this.recalculateAndSaveOverlays(t,n)))}getDocumentsMatchingQuery(t,e,n,s){return bp(e)?this.getDocumentsMatchingDocumentQuery(t,e.path):kh(e)?this.getDocumentsMatchingCollectionGroupQuery(t,e,n,s):this.getDocumentsMatchingCollectionQuery(t,e,n,s)}getNextDocuments(t,e,n,s){return this.remoteDocumentCache.getAllFromCollectionGroup(t,e,n,s).next((i=>{const a=s-i.size>0?this.documentOverlayCache.getOverlaysForCollectionGroup(t,e,n.largestBatchId,s-i.size):v.resolve(Wt());let u=bn,l=i;return a.next((d=>v.forEach(d,((f,g)=>(u<g.largestBatchId&&(u=g.largestBatchId),i.get(f)?v.resolve():this.remoteDocumentCache.getEntry(t,f).next((E=>{l=l.insert(f,E)}))))).next((()=>this.populateOverlays(t,d,i))).next((()=>this.computeViews(t,l,d,$()))).next((f=>({batchId:u,changes:Bh(f)})))))}))}getDocumentsMatchingDocumentQuery(t,e){return this.getDocument(t,new N(e)).next((n=>{let s=yr();return n.isFoundDocument()&&(s=s.insert(n.key,n)),s}))}getDocumentsMatchingCollectionGroupQuery(t,e,n,s){const i=e.collectionGroup;let a=yr();return this.indexManager.getCollectionParents(t,i).next((u=>v.forEach(u,(l=>{const d=(function(g,E){return new $n(E,null,g.explicitOrderBy.slice(),g.filters.slice(),g.limit,g.limitType,g.startAt,g.endAt)})(e,l.child(i));return this.getDocumentsMatchingCollectionQuery(t,d,n,s).next((f=>{f.forEach(((g,E)=>{a=a.insert(g,E)}))}))})).next((()=>a))))}getDocumentsMatchingCollectionQuery(t,e,n,s){let i;return this.documentOverlayCache.getOverlaysForCollection(t,e.path,n.largestBatchId).next((a=>(i=a,this.remoteDocumentCache.getDocumentsMatchingQuery(t,e,n,i,s)))).next((a=>{i.forEach(((l,d)=>{const f=d.getKey();a.get(f)===null&&(a=a.insert(f,ct.newInvalidDocument(f)))}));let u=yr();return a.forEach(((l,d)=>{const f=i.get(l);f!==void 0&&Cr(f.mutation,d,xt.empty(),X.now()),Yr(e,d)&&(u=u.insert(l,d))})),u}))}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class T_{constructor(t){this.serializer=t,this.Nr=new Map,this.Br=new Map}getBundleMetadata(t,e){return v.resolve(this.Nr.get(e))}saveBundleMetadata(t,e){return this.Nr.set(e.id,(function(s){return{id:s.id,version:s.version,createTime:Pt(s.createTime)}})(e)),v.resolve()}getNamedQuery(t,e){return v.resolve(this.Br.get(e))}saveNamedQuery(t,e){return this.Br.set(e.name,(function(s){return{name:s.name,query:fd(s.bundledQuery),readTime:Pt(s.readTime)}})(e)),v.resolve()}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class w_{constructor(){this.overlays=new nt(N.comparator),this.Lr=new Map}getOverlay(t,e){return v.resolve(this.overlays.get(e))}getOverlays(t,e){const n=Wt();return v.forEach(e,(s=>this.getOverlay(t,s).next((i=>{i!==null&&n.set(s,i)})))).next((()=>n))}saveOverlays(t,e,n){return n.forEach(((s,i)=>{this.St(t,e,i)})),v.resolve()}removeOverlaysForBatchId(t,e,n){const s=this.Lr.get(n);return s!==void 0&&(s.forEach((i=>this.overlays=this.overlays.remove(i))),this.Lr.delete(n)),v.resolve()}getOverlaysForCollection(t,e,n){const s=Wt(),i=e.length+1,a=new N(e.child("")),u=this.overlays.getIteratorFrom(a);for(;u.hasNext();){const l=u.getNext().value,d=l.getKey();if(!e.isPrefixOf(d.path))break;d.path.length===i&&l.largestBatchId>n&&s.set(l.getKey(),l)}return v.resolve(s)}getOverlaysForCollectionGroup(t,e,n,s){let i=new nt(((d,f)=>d-f));const a=this.overlays.getIterator();for(;a.hasNext();){const d=a.getNext().value;if(d.getKey().getCollectionGroup()===e&&d.largestBatchId>n){let f=i.get(d.largestBatchId);f===null&&(f=Wt(),i=i.insert(d.largestBatchId,f)),f.set(d.getKey(),d)}}const u=Wt(),l=i.getIterator();for(;l.hasNext()&&(l.getNext().value.forEach(((d,f)=>u.set(d,f))),!(u.size()>=s)););return v.resolve(u)}St(t,e,n){const s=this.overlays.get(n.key);if(s!==null){const a=this.Lr.get(s.largestBatchId).delete(n.key);this.Lr.set(s.largestBatchId,a)}this.overlays=this.overlays.insert(n.key,new fa(e,n));let i=this.Lr.get(e);i===void 0&&(i=$(),this.Lr.set(e,i)),this.Lr.set(e,i.add(n.key))}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class v_{constructor(){this.sessionToken=ht.EMPTY_BYTE_STRING}getSessionToken(t){return v.resolve(this.sessionToken)}setSessionToken(t,e){return this.sessionToken=e,v.resolve()}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ya{constructor(){this.kr=new tt(It.qr),this.Kr=new tt(It.Ur)}isEmpty(){return this.kr.isEmpty()}addReference(t,e){const n=new It(t,e);this.kr=this.kr.add(n),this.Kr=this.Kr.add(n)}$r(t,e){t.forEach((n=>this.addReference(n,e)))}removeReference(t,e){this.Wr(new It(t,e))}Qr(t,e){t.forEach((n=>this.removeReference(n,e)))}Gr(t){const e=new N(new Y([])),n=new It(e,t),s=new It(e,t+1),i=[];return this.Kr.forEachInRange([n,s],(a=>{this.Wr(a),i.push(a.key)})),i}zr(){this.kr.forEach((t=>this.Wr(t)))}Wr(t){this.kr=this.kr.delete(t),this.Kr=this.Kr.delete(t)}jr(t){const e=new N(new Y([])),n=new It(e,t),s=new It(e,t+1);let i=$();return this.Kr.forEachInRange([n,s],(a=>{i=i.add(a.key)})),i}containsKey(t){const e=new It(t,0),n=this.kr.firstAfterOrEqual(e);return n!==null&&t.isEqual(n.key)}}class It{constructor(t,e){this.key=t,this.Jr=e}static qr(t,e){return N.comparator(t.key,e.key)||U(t.Jr,e.Jr)}static Ur(t,e){return U(t.Jr,e.Jr)||N.comparator(t.key,e.key)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class A_{constructor(t,e){this.indexManager=t,this.referenceDelegate=e,this.mutationQueue=[],this.Yn=1,this.Hr=new tt(It.qr)}checkEmpty(t){return v.resolve(this.mutationQueue.length===0)}addMutationBatch(t,e,n,s){const i=this.Yn;this.Yn++,this.mutationQueue.length>0&&this.mutationQueue[this.mutationQueue.length-1];const a=new ha(i,e,n,s);this.mutationQueue.push(a);for(const u of s)this.Hr=this.Hr.add(new It(u.key,i)),this.indexManager.addToCollectionParentIndex(t,u.key.path.popLast());return v.resolve(a)}lookupMutationBatch(t,e){return v.resolve(this.Zr(e))}getNextMutationBatchAfterBatchId(t,e){const n=e+1,s=this.Xr(n),i=s<0?0:s;return v.resolve(this.mutationQueue.length>i?this.mutationQueue[i]:null)}getHighestUnacknowledgedBatchId(){return v.resolve(this.mutationQueue.length===0?Ke:this.Yn-1)}getAllMutationBatches(t){return v.resolve(this.mutationQueue.slice())}getAllMutationBatchesAffectingDocumentKey(t,e){const n=new It(e,0),s=new It(e,Number.POSITIVE_INFINITY),i=[];return this.Hr.forEachInRange([n,s],(a=>{const u=this.Zr(a.Jr);i.push(u)})),v.resolve(i)}getAllMutationBatchesAffectingDocumentKeys(t,e){let n=new tt(U);return e.forEach((s=>{const i=new It(s,0),a=new It(s,Number.POSITIVE_INFINITY);this.Hr.forEachInRange([i,a],(u=>{n=n.add(u.Jr)}))})),v.resolve(this.Yr(n))}getAllMutationBatchesAffectingQuery(t,e){const n=e.path,s=n.length+1;let i=n;N.isDocumentKey(i)||(i=i.child(""));const a=new It(new N(i),0);let u=new tt(U);return this.Hr.forEachWhile((l=>{const d=l.key.path;return!!n.isPrefixOf(d)&&(d.length===s&&(u=u.add(l.Jr)),!0)}),a),v.resolve(this.Yr(u))}Yr(t){const e=[];return t.forEach((n=>{const s=this.Zr(n);s!==null&&e.push(s)})),e}removeMutationBatch(t,e){L(this.ei(e.batchId,"removed")===0,55003),this.mutationQueue.shift();let n=this.Hr;return v.forEach(e.mutations,(s=>{const i=new It(s.key,e.batchId);return n=n.delete(i),this.referenceDelegate.markPotentiallyOrphaned(t,s.key)})).next((()=>{this.Hr=n}))}nr(t){}containsKey(t,e){const n=new It(e,0),s=this.Hr.firstAfterOrEqual(n);return v.resolve(e.isEqual(s&&s.key))}performConsistencyCheck(t){return this.mutationQueue.length,v.resolve()}ei(t,e){return this.Xr(t)}Xr(t){return this.mutationQueue.length===0?0:t-this.mutationQueue[0].batchId}Zr(t){const e=this.Xr(t);return e<0||e>=this.mutationQueue.length?null:this.mutationQueue[e]}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class b_{constructor(t){this.ti=t,this.docs=(function(){return new nt(N.comparator)})(),this.size=0}setIndexManager(t){this.indexManager=t}addEntry(t,e){const n=e.key,s=this.docs.get(n),i=s?s.size:0,a=this.ti(e);return this.docs=this.docs.insert(n,{document:e.mutableCopy(),size:a}),this.size+=a-i,this.indexManager.addToCollectionParentIndex(t,n.path.popLast())}removeEntry(t){const e=this.docs.get(t);e&&(this.docs=this.docs.remove(t),this.size-=e.size)}getEntry(t,e){const n=this.docs.get(e);return v.resolve(n?n.document.mutableCopy():ct.newInvalidDocument(e))}getEntries(t,e){let n=Mt();return e.forEach((s=>{const i=this.docs.get(s);n=n.insert(s,i?i.document.mutableCopy():ct.newInvalidDocument(s))})),v.resolve(n)}getDocumentsMatchingQuery(t,e,n,s){let i=Mt();const a=e.path,u=new N(a.child("__id-9223372036854775808__")),l=this.docs.getIteratorFrom(u);for(;l.hasNext();){const{key:d,value:{document:f}}=l.getNext();if(!a.isPrefixOf(d.path))break;d.path.length>a.length+1||Zo(eh(f),n)<=0||(s.has(f.key)||Yr(e,f))&&(i=i.insert(f.key,f.mutableCopy()))}return v.resolve(i)}getAllFromCollectionGroup(t,e,n,s){O(9500)}ni(t,e){return v.forEach(this.docs,(n=>e(n)))}newChangeBuffer(t){return new R_(this)}getSize(t){return v.resolve(this.size)}}class R_ extends vd{constructor(t){super(),this.Mr=t}applyChanges(t){const e=[];return this.changes.forEach(((n,s)=>{s.isValidDocument()?e.push(this.Mr.addEntry(t,s)):this.Mr.removeEntry(n)})),v.waitFor(e)}getFromCache(t,e){return this.Mr.getEntry(t,e)}getAllFromCache(t,e){return this.Mr.getEntries(t,e)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class S_{constructor(t){this.persistence=t,this.ri=new se((e=>Xe(e)),Wr),this.lastRemoteSnapshotVersion=B.min(),this.highestTargetId=0,this.ii=0,this.si=new ya,this.targetCount=0,this.oi=en._r()}forEachTarget(t,e){return this.ri.forEach(((n,s)=>e(s))),v.resolve()}getLastRemoteSnapshotVersion(t){return v.resolve(this.lastRemoteSnapshotVersion)}getHighestSequenceNumber(t){return v.resolve(this.ii)}allocateTargetId(t){return this.highestTargetId=this.oi.next(),v.resolve(this.highestTargetId)}setTargetsMetadata(t,e,n){return n&&(this.lastRemoteSnapshotVersion=n),e>this.ii&&(this.ii=e),v.resolve()}lr(t){this.ri.set(t.target,t);const e=t.targetId;e>this.highestTargetId&&(this.oi=new en(e),this.highestTargetId=e),t.sequenceNumber>this.ii&&(this.ii=t.sequenceNumber)}addTargetData(t,e){return this.lr(e),this.targetCount+=1,v.resolve()}updateTargetData(t,e){return this.lr(e),v.resolve()}removeTargetData(t,e){return this.ri.delete(e.target),this.si.Gr(e.targetId),this.targetCount-=1,v.resolve()}removeTargets(t,e,n){let s=0;const i=[];return this.ri.forEach(((a,u)=>{u.sequenceNumber<=e&&n.get(u.targetId)===null&&(this.ri.delete(a),i.push(this.removeMatchingKeysForTargetId(t,u.targetId)),s++)})),v.waitFor(i).next((()=>s))}getTargetCount(t){return v.resolve(this.targetCount)}getTargetData(t,e){const n=this.ri.get(e)||null;return v.resolve(n)}addMatchingKeys(t,e,n){return this.si.$r(e,n),v.resolve()}removeMatchingKeys(t,e,n){this.si.Qr(e,n);const s=this.persistence.referenceDelegate,i=[];return s&&e.forEach((a=>{i.push(s.markPotentiallyOrphaned(t,a))})),v.waitFor(i)}removeMatchingKeysForTargetId(t,e){return this.si.Gr(e),v.resolve()}getMatchingKeysForTargetId(t,e){const n=this.si.jr(e);return v.resolve(n)}containsKey(t,e){return v.resolve(this.si.containsKey(e))}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Ia{constructor(t,e){this._i={},this.overlays={},this.ai=new Dt(0),this.ui=!1,this.ui=!0,this.ci=new v_,this.referenceDelegate=t(this),this.li=new S_(this),this.indexManager=new d_,this.remoteDocumentCache=(function(s){return new b_(s)})((n=>this.referenceDelegate.hi(n))),this.serializer=new hd(e),this.Pi=new T_(this.serializer)}start(){return Promise.resolve()}shutdown(){return this.ui=!1,Promise.resolve()}get started(){return this.ui}setDatabaseDeletedListener(){}setNetworkEnabled(){}getIndexManager(t){return this.indexManager}getDocumentOverlayCache(t){let e=this.overlays[t.toKey()];return e||(e=new w_,this.overlays[t.toKey()]=e),e}getMutationQueue(t,e){let n=this._i[t.toKey()];return n||(n=new A_(e,this.referenceDelegate),this._i[t.toKey()]=n),n}getGlobalsCache(){return this.ci}getTargetCache(){return this.li}getRemoteDocumentCache(){return this.remoteDocumentCache}getBundleCache(){return this.Pi}runTransaction(t,e,n){P("MemoryPersistence","Starting transaction:",t);const s=new V_(this.ai.next());return this.referenceDelegate.Ti(),n(s).next((i=>this.referenceDelegate.Ei(s).next((()=>i)))).toPromise().then((i=>(s.raiseOnCommittedEvent(),i)))}Ii(t,e){return v.or(Object.values(this._i).map((n=>()=>n.containsKey(t,e))))}}class V_ extends rh{constructor(t){super(),this.currentSequenceNumber=t}}class vi{constructor(t){this.persistence=t,this.Ri=new ya,this.Ai=null}static Vi(t){return new vi(t)}get di(){if(this.Ai)return this.Ai;throw O(60996)}addReference(t,e,n){return this.Ri.addReference(n,e),this.di.delete(n.toString()),v.resolve()}removeReference(t,e,n){return this.Ri.removeReference(n,e),this.di.add(n.toString()),v.resolve()}markPotentiallyOrphaned(t,e){return this.di.add(e.toString()),v.resolve()}removeTarget(t,e){this.Ri.Gr(e.targetId).forEach((s=>this.di.add(s.toString())));const n=this.persistence.getTargetCache();return n.getMatchingKeysForTargetId(t,e.targetId).next((s=>{s.forEach((i=>this.di.add(i.toString())))})).next((()=>n.removeTargetData(t,e)))}Ti(){this.Ai=new Set}Ei(t){const e=this.persistence.getRemoteDocumentCache().newChangeBuffer();return v.forEach(this.di,(n=>{const s=N.fromPath(n);return this.mi(t,s).next((i=>{i||e.removeEntry(s,B.min())}))})).next((()=>(this.Ai=null,e.apply(t))))}updateLimboDocument(t,e){return this.mi(t,e).next((n=>{n?this.di.delete(e.toString()):this.di.add(e.toString())}))}hi(t){return 0}mi(t,e){return v.or([()=>v.resolve(this.Ri.containsKey(e)),()=>this.persistence.getTargetCache().containsKey(t,e),()=>this.persistence.Ii(t,e)])}}class ei{constructor(t,e){this.persistence=t,this.fi=new se((n=>Rt(n.path)),((n,s)=>n.isEqual(s))),this.garbageCollector=wd(this,e)}static Vi(t,e){return new ei(t,e)}Ti(){}Ei(t){return v.resolve()}forEachTarget(t,e){return this.persistence.getTargetCache().forEachTarget(t,e)}dr(t){const e=this.pr(t);return this.persistence.getTargetCache().getTargetCount(t).next((n=>e.next((s=>n+s))))}pr(t){let e=0;return this.mr(t,(n=>{e++})).next((()=>e))}mr(t,e){return v.forEach(this.fi,((n,s)=>this.wr(t,n,s).next((i=>i?v.resolve():e(s)))))}removeTargets(t,e,n){return this.persistence.getTargetCache().removeTargets(t,e,n)}removeOrphanedDocuments(t,e){let n=0;const s=this.persistence.getRemoteDocumentCache(),i=s.newChangeBuffer();return s.ni(t,(a=>this.wr(t,a,e).next((u=>{u||(n++,i.removeEntry(a,B.min()))})))).next((()=>i.apply(t))).next((()=>n))}markPotentiallyOrphaned(t,e){return this.fi.set(e,t.currentSequenceNumber),v.resolve()}removeTarget(t,e){const n=e.withSequenceNumber(t.currentSequenceNumber);return this.persistence.getTargetCache().updateTargetData(t,n)}addReference(t,e,n){return this.fi.set(n,t.currentSequenceNumber),v.resolve()}removeReference(t,e,n){return this.fi.set(n,t.currentSequenceNumber),v.resolve()}updateLimboDocument(t,e){return this.fi.set(e,t.currentSequenceNumber),v.resolve()}hi(t){let e=t.key.toString().length;return t.isFoundDocument()&&(e+=Ns(t.data.value)),e}wr(t,e,n){return v.or([()=>this.persistence.Ii(t,e),()=>this.persistence.getTargetCache().containsKey(t,e),()=>{const s=this.fi.get(e);return v.resolve(s!==void 0&&s>n)}])}getCacheSize(t){return this.persistence.getRemoteDocumentCache().getSize(t)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class P_{constructor(t){this.serializer=t}k(t,e,n,s){const i=new hi("createOrUpgrade",e);n<1&&s>=1&&((function(l){l.createObjectStore(Qr)})(t),(function(l){l.createObjectStore(Or,{keyPath:qg}),l.createObjectStore(qt,{keyPath:mc,autoIncrement:!0}).createIndex(Ge,gc,{unique:!0}),l.createObjectStore(Rn)})(t),sl(t),(function(l){l.createObjectStore(Ue)})(t));let a=v.resolve();return n<3&&s>=3&&(n!==0&&((function(l){l.deleteObjectStore(Vn),l.deleteObjectStore(Sn),l.deleteObjectStore(He)})(t),sl(t)),a=a.next((()=>(function(l){const d=l.store(He),f={highestTargetId:0,highestListenSequenceNumber:0,lastRemoteSnapshotVersion:B.min().toTimestamp(),targetCount:0};return d.put(Ks,f)})(i)))),n<4&&s>=4&&(n!==0&&(a=a.next((()=>(function(l,d){return d.store(qt).J().next((g=>{l.deleteObjectStore(qt),l.createObjectStore(qt,{keyPath:mc,autoIncrement:!0}).createIndex(Ge,gc,{unique:!0});const E=d.store(qt),V=g.map((D=>E.put(D)));return v.waitFor(V)}))})(t,i)))),a=a.next((()=>{(function(l){l.createObjectStore(Pn,{keyPath:Jg})})(t)}))),n<5&&s>=5&&(a=a.next((()=>this.gi(i)))),n<6&&s>=6&&(a=a.next((()=>((function(l){l.createObjectStore(Fr)})(t),this.pi(i))))),n<7&&s>=7&&(a=a.next((()=>this.yi(i)))),n<8&&s>=8&&(a=a.next((()=>this.wi(t,i)))),n<9&&s>=9&&(a=a.next((()=>{(function(l){l.objectStoreNames.contains("remoteDocumentChanges")&&l.deleteObjectStore("remoteDocumentChanges")})(t)}))),n<10&&s>=10&&(a=a.next((()=>this.Si(i)))),n<11&&s>=11&&(a=a.next((()=>{(function(l){l.createObjectStore(fi,{keyPath:Yg})})(t),(function(l){l.createObjectStore(mi,{keyPath:Xg})})(t)}))),n<12&&s>=12&&(a=a.next((()=>{(function(l){const d=l.createObjectStore(gi,{keyPath:ip});d.createIndex(Po,op,{unique:!1}),d.createIndex(hh,ap,{unique:!1})})(t)}))),n<13&&s>=13&&(a=a.next((()=>(function(l){const d=l.createObjectStore(Gs,{keyPath:zg});d.createIndex(Ds,$g),d.createIndex(ah,Gg)})(t))).next((()=>this.bi(t,i))).next((()=>t.deleteObjectStore(Ue)))),n<14&&s>=14&&(a=a.next((()=>this.Di(t,i)))),n<15&&s>=15&&(a=a.next((()=>(function(l){l.createObjectStore(na,{keyPath:Zg,autoIncrement:!0}).createIndex(Vo,tp,{unique:!1}),l.createObjectStore(br,{keyPath:ep}).createIndex(ch,np,{unique:!1}),l.createObjectStore(Rr,{keyPath:rp}).createIndex(lh,sp,{unique:!1})})(t)))),n<16&&s>=16&&(a=a.next((()=>{e.objectStore(br).clear()})).next((()=>{e.objectStore(Rr).clear()}))),n<17&&s>=17&&(a=a.next((()=>{(function(l){l.createObjectStore(ra,{keyPath:up})})(t)}))),n<18&&s>=18&&Ml()&&(a=a.next((()=>{e.objectStore(br).clear()})).next((()=>{e.objectStore(Rr).clear()}))),a}pi(t){let e=0;return t.store(Ue).ee(((n,s)=>{e+=ti(s)})).next((()=>{const n={byteSize:e};return t.store(Fr).put(So,n)}))}gi(t){const e=t.store(Or),n=t.store(qt);return e.J().next((s=>v.forEach(s,(i=>{const a=IDBKeyRange.bound([i.userId,Ke],[i.userId,i.lastAcknowledgedBatchId]);return n.J(Ge,a).next((u=>v.forEach(u,(l=>{L(l.userId===i.userId,18650,"Cannot process batch from unexpected user",{batchId:l.batchId});const d=je(this.serializer,l);return _d(t,i.userId,d).next((()=>{}))}))))}))))}yi(t){const e=t.store(Vn),n=t.store(Ue);return t.store(He).get(Ks).next((s=>{const i=[];return n.ee(((a,u)=>{const l=new Y(a),d=(function(g){return[0,Rt(g)]})(l);i.push(e.get(d).next((f=>f?v.resolve():(g=>e.put({targetId:0,path:Rt(g),sequenceNumber:s.highestListenSequenceNumber}))(l))))})).next((()=>v.waitFor(i)))}))}wi(t,e){t.createObjectStore(Lr,{keyPath:Wg});const n=e.store(Lr),s=new _a,i=a=>{if(s.add(a)){const u=a.lastSegment(),l=a.popLast();return n.put({collectionId:u,parent:Rt(l)})}};return e.store(Ue).ee({Y:!0},((a,u)=>{const l=new Y(a);return i(l.popLast())})).next((()=>e.store(Rn).ee({Y:!0},(([a,u,l],d)=>{const f=Qt(u);return i(f.popLast())}))))}Si(t){const e=t.store(Sn);return e.ee(((n,s)=>{const i=Er(s),a=dd(this.serializer,i);return e.put(a)}))}bi(t,e){const n=e.store(Ue),s=[];return n.ee(((i,a)=>{const u=e.store(Gs),l=(function(g){return g.document?new N(Y.fromString(g.document.name).popFirst(5)):g.noDocument?N.fromSegments(g.noDocument.path):g.unknownDocument?N.fromSegments(g.unknownDocument.path):O(36783)})(a).path.toArray(),d={prefixPath:l.slice(0,l.length-2),collectionGroup:l[l.length-2],documentId:l[l.length-1],readTime:a.readTime||[0,0],unknownDocument:a.unknownDocument,noDocument:a.noDocument,document:a.document,hasCommittedMutations:!!a.hasCommittedMutations};s.push(u.put(d))})).next((()=>v.waitFor(s)))}Di(t,e){const n=e.store(qt),s=Ad(this.serializer),i=new Ia(vi.Vi,this.serializer.yt);return n.J().next((a=>{const u=new Map;return a.forEach((l=>{let d=u.get(l.userId)??$();je(this.serializer,l).keys().forEach((f=>d=d.add(f))),u.set(l.userId,d)})),v.forEach(u,((l,d)=>{const f=new vt(d),g=Ti.wt(this.serializer,f),E=i.getIndexManager(f),V=wi.wt(f,this.serializer,E,i.referenceDelegate);return new bd(s,V,g,E).recalculateAndSaveOverlaysForDocumentKeys(new Co(e,Dt.ce),l).next()}))}))}}function sl(r){r.createObjectStore(Vn,{keyPath:Hg}).createIndex(ea,Qg,{unique:!0}),r.createObjectStore(Sn,{keyPath:"targetId"}).createIndex(uh,Kg,{unique:!0}),r.createObjectStore(He)}const me="IndexedDbPersistence",lo=18e5,ho=5e3,fo="Failed to obtain exclusive access to the persistence layer. To allow shared access, multi-tab synchronization has to be enabled in all tabs. If you are using `experimentalForceOwningTab:true`, make sure that only one tab has persistence enabled at any given time.",C_="main";class Ea{constructor(t,e,n,s,i,a,u,l,d,f,g=18){if(this.allowTabSynchronization=t,this.persistenceKey=e,this.clientId=n,this.Ci=i,this.window=a,this.document=u,this.Fi=d,this.Mi=f,this.xi=g,this.ai=null,this.ui=!1,this.isPrimary=!1,this.networkEnabled=!0,this.Oi=null,this.inForeground=!1,this.Ni=null,this.Bi=null,this.Li=Number.NEGATIVE_INFINITY,this.ki=E=>Promise.resolve(),!Ea.v())throw new C(S.UNIMPLEMENTED,"This platform is either missing IndexedDB or is known to have an incomplete implementation. Offline persistence has been disabled.");this.referenceDelegate=new __(this,s),this.qi=e+C_,this.serializer=new hd(l),this.Ki=new Ee(this.qi,this.xi,new P_(this.serializer)),this.ci=new o_,this.li=new m_(this.referenceDelegate,this.serializer),this.remoteDocumentCache=Ad(this.serializer),this.Pi=new i_,this.window&&this.window.localStorage?this.Ui=this.window.localStorage:(this.Ui=null,f===!1&&lt(me,"LocalStorage is unavailable. As a result, persistence may not work reliably. In particular enablePersistence() could fail immediately after refreshing the page."))}start(){return this.$i().then((()=>{if(!this.isPrimary&&!this.allowTabSynchronization)throw new C(S.FAILED_PRECONDITION,fo);return this.Wi(),this.Qi(),this.Gi(),this.runTransaction("getHighestListenSequenceNumber","readonly",(t=>this.li.getHighestSequenceNumber(t)))})).then((t=>{this.ai=new Dt(t,this.Fi)})).then((()=>{this.ui=!0})).catch((t=>(this.Ki&&this.Ki.close(),Promise.reject(t))))}zi(t){return this.ki=async e=>{if(this.started)return t(e)},t(this.isPrimary)}setDatabaseDeletedListener(t){this.Ki.K((async e=>{e.newVersion===null&&await t()}))}setNetworkEnabled(t){this.networkEnabled!==t&&(this.networkEnabled=t,this.Ci.enqueueAndForget((async()=>{this.started&&await this.$i()})))}$i(){return this.runTransaction("updateClientMetadataAndTryBecomePrimary","readwrite",(t=>Rs(t).put({clientId:this.clientId,updateTimeMs:Date.now(),networkEnabled:this.networkEnabled,inForeground:this.inForeground}).next((()=>{if(this.isPrimary)return this.ji(t).next((e=>{e||(this.isPrimary=!1,this.Ci.enqueueRetryable((()=>this.ki(!1))))}))})).next((()=>this.Ji(t))).next((e=>this.isPrimary&&!e?this.Hi(t).next((()=>!1)):!!e&&this.Zi(t).next((()=>!0)))))).catch((t=>{if(Se(t))return P(me,"Failed to extend owner lease: ",t),this.isPrimary;if(!this.allowTabSynchronization)throw t;return P(me,"Releasing owner lease after error during lease refresh",t),!1})).then((t=>{this.isPrimary!==t&&this.Ci.enqueueRetryable((()=>this.ki(t))),this.isPrimary=t}))}ji(t){return gr(t).get(cn).next((e=>v.resolve(this.Xi(e))))}Yi(t){return Rs(t).delete(this.clientId)}async es(){if(this.isPrimary&&!this.ts(this.Li,lo)){this.Li=Date.now();const t=await this.runTransaction("maybeGarbageCollectMultiClientState","readwrite-primary",(e=>{const n=_t(e,Pn);return n.J().next((s=>{const i=this.ns(s,lo),a=s.filter((u=>i.indexOf(u)===-1));return v.forEach(a,(u=>n.delete(u.clientId))).next((()=>a))}))})).catch((()=>[]));if(this.Ui)for(const e of t)this.Ui.removeItem(this.rs(e.clientId))}}Gi(){this.Bi=this.Ci.enqueueAfterDelay("client_metadata_refresh",4e3,(()=>this.$i().then((()=>this.es())).then((()=>this.Gi()))))}Xi(t){return!!t&&t.ownerId===this.clientId}Ji(t){return this.Mi?v.resolve(!0):gr(t).get(cn).next((e=>{if(e!==null&&this.ts(e.leaseTimestampMs,ho)&&!this.ss(e.ownerId)){if(this.Xi(e)&&this.networkEnabled)return!0;if(!this.Xi(e)){if(!e.allowTabSynchronization)throw new C(S.FAILED_PRECONDITION,fo);return!1}}return!(!this.networkEnabled||!this.inForeground)||Rs(t).J().next((n=>this.ns(n,ho).find((s=>{if(this.clientId!==s.clientId){const i=!this.networkEnabled&&s.networkEnabled,a=!this.inForeground&&s.inForeground,u=this.networkEnabled===s.networkEnabled;if(i||a&&u)return!0}return!1}))===void 0))})).next((e=>(this.isPrimary!==e&&P(me,`Client ${e?"is":"is not"} eligible for a primary lease.`),e)))}async shutdown(){this.ui=!1,this._s(),this.Bi&&(this.Bi.cancel(),this.Bi=null),this.us(),this.cs(),await this.Ki.runTransaction("shutdown","readwrite",[Qr,Pn],(t=>{const e=new Co(t,Dt.ce);return this.Hi(e).next((()=>this.Yi(e)))})),this.Ki.close(),this.ls()}ns(t,e){return t.filter((n=>this.ts(n.updateTimeMs,e)&&!this.ss(n.clientId)))}hs(){return this.runTransaction("getActiveClients","readonly",(t=>Rs(t).J().next((e=>this.ns(e,lo).map((n=>n.clientId))))))}get started(){return this.ui}getGlobalsCache(){return this.ci}getMutationQueue(t,e){return wi.wt(t,this.serializer,e,this.referenceDelegate)}getTargetCache(){return this.li}getRemoteDocumentCache(){return this.remoteDocumentCache}getIndexManager(t){return new f_(t,this.serializer.yt.databaseId)}getDocumentOverlayCache(t){return Ti.wt(this.serializer,t)}getBundleCache(){return this.Pi}runTransaction(t,e,n){P(me,"Starting transaction:",t);const s=e==="readonly"?"readonly":"readwrite",i=(function(l){return l===18?hp:l===17?gh:l===16?lp:l===15?sa:l===14?mh:l===13?fh:l===12?cp:l===11?dh:void O(60245)})(this.xi);let a;return this.Ki.runTransaction(t,s,i,(u=>(a=new Co(u,this.ai?this.ai.next():Dt.ce),e==="readwrite-primary"?this.ji(a).next((l=>!!l||this.Ji(a))).next((l=>{if(!l)throw lt(`Failed to obtain primary lease for action '${t}'.`),this.isPrimary=!1,this.Ci.enqueueRetryable((()=>this.ki(!1))),new C(S.FAILED_PRECONDITION,nh);return n(a)})).next((l=>this.Zi(a).next((()=>l)))):this.Ps(a).next((()=>n(a)))))).then((u=>(a.raiseOnCommittedEvent(),u)))}Ps(t){return gr(t).get(cn).next((e=>{if(e!==null&&this.ts(e.leaseTimestampMs,ho)&&!this.ss(e.ownerId)&&!this.Xi(e)&&!(this.Mi||this.allowTabSynchronization&&e.allowTabSynchronization))throw new C(S.FAILED_PRECONDITION,fo)}))}Zi(t){const e={ownerId:this.clientId,allowTabSynchronization:this.allowTabSynchronization,leaseTimestampMs:Date.now()};return gr(t).put(cn,e)}static v(){return Ee.v()}Hi(t){const e=gr(t);return e.get(cn).next((n=>this.Xi(n)?(P(me,"Releasing primary lease."),e.delete(cn)):v.resolve()))}ts(t,e){const n=Date.now();return!(t<n-e)&&(!(t>n)||(lt(`Detected an update time that is in the future: ${t} > ${n}`),!1))}Wi(){this.document!==null&&typeof this.document.addEventListener=="function"&&(this.Ni=()=>{this.Ci.enqueueAndForget((()=>(this.inForeground=this.document.visibilityState==="visible",this.$i())))},this.document.addEventListener("visibilitychange",this.Ni),this.inForeground=this.document.visibilityState==="visible")}us(){this.Ni&&(this.document.removeEventListener("visibilitychange",this.Ni),this.Ni=null)}Qi(){var t;typeof((t=this.window)==null?void 0:t.addEventListener)=="function"&&(this.Oi=()=>{this._s();const e=/(?:Version|Mobile)\/1[456]/;kl()&&(navigator.appVersion.match(e)||navigator.userAgent.match(e))&&this.Ci.enterRestrictedMode(!0),this.Ci.enqueueAndForget((()=>this.shutdown()))},this.window.addEventListener("pagehide",this.Oi))}cs(){this.Oi&&(this.window.removeEventListener("pagehide",this.Oi),this.Oi=null)}ss(t){var e;try{const n=((e=this.Ui)==null?void 0:e.getItem(this.rs(t)))!==null;return P(me,`Client '${t}' ${n?"is":"is not"} zombied in LocalStorage`),n}catch(n){return lt(me,"Failed to get zombied client id.",n),!1}}_s(){if(this.Ui)try{this.Ui.setItem(this.rs(this.clientId),String(Date.now()))}catch(t){lt("Failed to set zombie client id.",t)}}ls(){if(this.Ui)try{this.Ui.removeItem(this.rs(this.clientId))}catch{}}rs(t){return`firestore_zombie_${this.persistenceKey}_${t}`}}function gr(r){return _t(r,Qr)}function Rs(r){return _t(r,Pn)}function Rd(r,t){let e=r.projectId;return r.isDefaultDatabase||(e+="."+r.database),"firestore/"+t+"/"+e+"/"}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Ta{constructor(t,e,n,s){this.targetId=t,this.fromCache=e,this.Ts=n,this.Es=s}static Is(t,e){let n=$(),s=$();for(const i of e.docChanges)switch(i.type){case 0:n=n.add(i.doc.key);break;case 1:s=s.add(i.doc.key)}return new Ta(t,e.fromCache,n,s)}}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class D_{constructor(){this._documentReadCount=0}get documentReadCount(){return this._documentReadCount}incrementDocumentReadCount(t){this._documentReadCount+=t}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Sd{constructor(){this.Rs=!1,this.As=!1,this.Vs=100,this.ds=(function(){return kl()?8:sh(wn())>0?6:4})()}initialize(t,e){this.fs=t,this.indexManager=e,this.Rs=!0}getDocumentsMatchingQuery(t,e,n,s){const i={result:null};return this.gs(t,e).next((a=>{i.result=a})).next((()=>{if(!i.result)return this.ps(t,e,s,n).next((a=>{i.result=a}))})).next((()=>{if(i.result)return;const a=new D_;return this.ys(t,e,a).next((u=>{if(i.result=u,this.As)return this.ws(t,e,a,u.size)}))})).next((()=>i.result))}ws(t,e,n,s){return n.documentReadCount<this.Vs?(gn()<=Q.DEBUG&&P("QueryEngine","SDK will not create cache indexes for query:",pn(e),"since it only creates cache indexes for collection contains","more than or equal to",this.Vs,"documents"),v.resolve()):(gn()<=Q.DEBUG&&P("QueryEngine","Query:",pn(e),"scans",n.documentReadCount,"local documents and returns",s,"documents as results."),n.documentReadCount>this.ds*s?(gn()<=Q.DEBUG&&P("QueryEngine","The SDK decides to create cache indexes for query:",pn(e),"as using cache indexes may help improve performance."),this.indexManager.createTargetIndexes(t,Ot(e))):v.resolve())}gs(t,e){if(Vc(e))return v.resolve(null);let n=Ot(e);return this.indexManager.getIndexType(t,n).next((s=>s===0?null:(e.limit!==null&&s===1&&(e=Fo(e,null,"F"),n=Ot(e)),this.indexManager.getDocumentsMatchingTarget(t,n).next((i=>{const a=$(...i);return this.fs.getDocuments(t,a).next((u=>this.indexManager.getMinOffset(t,n).next((l=>{const d=this.Ss(e,u);return this.bs(e,d,a,l.readTime)?this.gs(t,Fo(e,null,"F")):this.Ds(t,d,e,l)}))))})))))}ps(t,e,n,s){return Vc(e)||s.isEqual(B.min())?v.resolve(null):this.fs.getDocuments(t,n).next((i=>{const a=this.Ss(e,i);return this.bs(e,a,n,s)?v.resolve(null):(gn()<=Q.DEBUG&&P("QueryEngine","Re-using previous result from %s to execute query: %s",s.toString(),pn(e)),this.Ds(t,a,e,th(s,bn)).next((u=>u)))}))}Ss(t,e){let n=new tt(Fh(t));return e.forEach(((s,i)=>{Yr(t,i)&&(n=n.add(i))})),n}bs(t,e,n,s){if(t.limit===null)return!1;if(n.size!==e.size)return!0;const i=t.limitType==="F"?e.last():e.first();return!!i&&(i.hasPendingWrites||i.version.compareTo(s)>0)}ys(t,e,n){return gn()<=Q.DEBUG&&P("QueryEngine","Using full collection scan to execute query:",pn(e)),this.fs.getDocumentsMatchingQuery(t,e,Ft.min(),n)}Ds(t,e,n,s){return this.fs.getDocumentsMatchingQuery(t,n,s).next((i=>(e.forEach((a=>{i=i.insert(a.key,a)})),i)))}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const wa="LocalStore",x_=3e8;class N_{constructor(t,e,n,s){this.persistence=t,this.Cs=e,this.serializer=s,this.vs=new nt(U),this.Fs=new se((i=>Xe(i)),Wr),this.Ms=new Map,this.xs=t.getRemoteDocumentCache(),this.li=t.getTargetCache(),this.Pi=t.getBundleCache(),this.Os(n)}Os(t){this.documentOverlayCache=this.persistence.getDocumentOverlayCache(t),this.indexManager=this.persistence.getIndexManager(t),this.mutationQueue=this.persistence.getMutationQueue(t,this.indexManager),this.localDocuments=new bd(this.xs,this.mutationQueue,this.documentOverlayCache,this.indexManager),this.xs.setIndexManager(this.indexManager),this.Cs.initialize(this.localDocuments,this.indexManager)}collectGarbage(t){return this.persistence.runTransaction("Collect garbage","readwrite-primary",(e=>t.collect(e,this.vs)))}}function Vd(r,t,e,n){return new N_(r,t,e,n)}async function Pd(r,t){const e=F(r);return await e.persistence.runTransaction("Handle user change","readonly",(n=>{let s;return e.mutationQueue.getAllMutationBatches(n).next((i=>(s=i,e.Os(t),e.mutationQueue.getAllMutationBatches(n)))).next((i=>{const a=[],u=[];let l=$();for(const d of s){a.push(d.batchId);for(const f of d.mutations)l=l.add(f.key)}for(const d of i){u.push(d.batchId);for(const f of d.mutations)l=l.add(f.key)}return e.localDocuments.getDocuments(n,l).next((d=>({Ns:d,removedBatchIds:a,addedBatchIds:u})))}))}))}function k_(r,t){const e=F(r);return e.persistence.runTransaction("Acknowledge batch","readwrite-primary",(n=>{const s=t.batch.keys(),i=e.xs.newChangeBuffer({trackRemovals:!0});return(function(u,l,d,f){const g=d.batch,E=g.keys();let V=v.resolve();return E.forEach((D=>{V=V.next((()=>f.getEntry(l,D))).next((k=>{const M=d.docVersions.get(D);L(M!==null,48541),k.version.compareTo(M)<0&&(g.applyToRemoteDocument(k,d),k.isValidDocument()&&(k.setReadTime(d.commitVersion),f.addEntry(k)))}))})),V.next((()=>u.mutationQueue.removeMutationBatch(l,g)))})(e,n,t,i).next((()=>i.apply(n))).next((()=>e.mutationQueue.performConsistencyCheck(n))).next((()=>e.documentOverlayCache.removeOverlaysForBatchId(n,s,t.batch.batchId))).next((()=>e.localDocuments.recalculateAndSaveOverlaysForDocumentKeys(n,(function(u){let l=$();for(let d=0;d<u.mutationResults.length;++d)u.mutationResults[d].transformResults.length>0&&(l=l.add(u.batch.mutations[d].key));return l})(t)))).next((()=>e.localDocuments.getDocuments(n,s)))}))}function Cd(r){const t=F(r);return t.persistence.runTransaction("Get last remote snapshot version","readonly",(e=>t.li.getLastRemoteSnapshotVersion(e)))}function M_(r,t){const e=F(r),n=t.snapshotVersion;let s=e.vs;return e.persistence.runTransaction("Apply remote event","readwrite-primary",(i=>{const a=e.xs.newChangeBuffer({trackRemovals:!0});s=e.vs;const u=[];t.targetChanges.forEach(((f,g)=>{const E=s.get(g);if(!E)return;u.push(e.li.removeMatchingKeys(i,f.removedDocuments,g).next((()=>e.li.addMatchingKeys(i,f.addedDocuments,g))));let V=E.withSequenceNumber(i.currentSequenceNumber);t.targetMismatches.get(g)!==null?V=V.withResumeToken(ht.EMPTY_BYTE_STRING,B.min()).withLastLimboFreeSnapshotVersion(B.min()):f.resumeToken.approximateByteSize()>0&&(V=V.withResumeToken(f.resumeToken,n)),s=s.insert(g,V),(function(k,M,K){return k.resumeToken.approximateByteSize()===0||M.snapshotVersion.toMicroseconds()-k.snapshotVersion.toMicroseconds()>=x_?!0:K.addedDocuments.size+K.modifiedDocuments.size+K.removedDocuments.size>0})(E,V,f)&&u.push(e.li.updateTargetData(i,V))}));let l=Mt(),d=$();if(t.documentUpdates.forEach((f=>{t.resolvedLimboDocuments.has(f)&&u.push(e.persistence.referenceDelegate.updateLimboDocument(i,f))})),u.push(O_(i,a,t.documentUpdates).next((f=>{l=f.Bs,d=f.Ls}))),!n.isEqual(B.min())){const f=e.li.getLastRemoteSnapshotVersion(i).next((g=>e.li.setTargetsMetadata(i,i.currentSequenceNumber,n)));u.push(f)}return v.waitFor(u).next((()=>a.apply(i))).next((()=>e.localDocuments.getLocalViewOfDocuments(i,l,d))).next((()=>l))})).then((i=>(e.vs=s,i)))}function O_(r,t,e){let n=$(),s=$();return e.forEach((i=>n=n.add(i))),t.getEntries(r,n).next((i=>{let a=Mt();return e.forEach(((u,l)=>{const d=i.get(u);l.isFoundDocument()!==d.isFoundDocument()&&(s=s.add(u)),l.isNoDocument()&&l.version.isEqual(B.min())?(t.removeEntry(u,l.readTime),a=a.insert(u,l)):!d.isValidDocument()||l.version.compareTo(d.version)>0||l.version.compareTo(d.version)===0&&d.hasPendingWrites?(t.addEntry(l),a=a.insert(u,l)):P(wa,"Ignoring outdated watch update for ",u,". Current version:",d.version," Watch version:",l.version)})),{Bs:a,Ls:s}}))}function F_(r,t){const e=F(r);return e.persistence.runTransaction("Get next mutation batch","readonly",(n=>(t===void 0&&(t=Ke),e.mutationQueue.getNextMutationBatchAfterBatchId(n,t))))}function ni(r,t){const e=F(r);return e.persistence.runTransaction("Allocate target","readwrite",(n=>{let s;return e.li.getTargetData(n,t).next((i=>i?(s=i,v.resolve(s)):e.li.allocateTargetId(n).next((a=>(s=new Zt(t,a,"TargetPurposeListen",n.currentSequenceNumber),e.li.addTargetData(n,s).next((()=>s)))))))})).then((n=>{const s=e.vs.get(n.targetId);return(s===null||n.snapshotVersion.compareTo(s.snapshotVersion)>0)&&(e.vs=e.vs.insert(n.targetId,n),e.Fs.set(t,n.targetId)),n}))}async function Ln(r,t,e){const n=F(r),s=n.vs.get(t),i=e?"readwrite":"readwrite-primary";try{e||await n.persistence.runTransaction("Release target",i,(a=>n.persistence.referenceDelegate.removeTarget(a,s)))}catch(a){if(!Se(a))throw a;P(wa,`Failed to update sequence numbers for target ${t}: ${a}`)}n.vs=n.vs.remove(t),n.Fs.delete(s.target)}function ri(r,t,e){const n=F(r);let s=B.min(),i=$();return n.persistence.runTransaction("Execute query","readwrite",(a=>(function(l,d,f){const g=F(l),E=g.Fs.get(f);return E!==void 0?v.resolve(g.vs.get(E)):g.li.getTargetData(d,f)})(n,a,Ot(t)).next((u=>{if(u)return s=u.lastLimboFreeSnapshotVersion,n.li.getMatchingKeysForTargetId(a,u.targetId).next((l=>{i=l}))})).next((()=>n.Cs.getDocumentsMatchingQuery(a,t,e?s:B.min(),e?i:$()))).next((u=>(Nd(n,Oh(t),u),{documents:u,ks:i})))))}function Dd(r,t){const e=F(r),n=F(e.li),s=e.vs.get(t);return s?Promise.resolve(s.target):e.persistence.runTransaction("Get target data","readonly",(i=>n.At(i,t).next((a=>a?a.target:null))))}function xd(r,t){const e=F(r),n=e.Ms.get(t)||B.min();return e.persistence.runTransaction("Get new document changes","readonly",(s=>e.xs.getAllFromCollectionGroup(s,t,th(n,bn),Number.MAX_SAFE_INTEGER))).then((s=>(Nd(e,t,s),s)))}function Nd(r,t,e){let n=r.Ms.get(t)||B.min();e.forEach(((s,i)=>{i.readTime.compareTo(n)>0&&(n=i.readTime)})),r.Ms.set(t,n)}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const kd="firestore_clients";function il(r,t){return`${kd}_${r}_${t}`}const Md="firestore_mutations";function ol(r,t,e){let n=`${Md}_${r}_${e}`;return t.isAuthenticated()&&(n+=`_${t.uid}`),n}const Od="firestore_targets";function mo(r,t){return`${Od}_${r}_${t}`}/**
 * @license
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Ht="SharedClientState";class si{constructor(t,e,n,s){this.user=t,this.batchId=e,this.state=n,this.error=s}static $s(t,e,n){const s=JSON.parse(n);let i,a=typeof s=="object"&&["pending","acknowledged","rejected"].indexOf(s.state)!==-1&&(s.error===void 0||typeof s.error=="object");return a&&s.error&&(a=typeof s.error.message=="string"&&typeof s.error.code=="string",a&&(i=new C(s.error.code,s.error.message))),a?new si(t,e,s.state,i):(lt(Ht,`Failed to parse mutation state for ID '${e}': ${n}`),null)}Ws(){const t={state:this.state,updateTimeMs:Date.now()};return this.error&&(t.error={code:this.error.code,message:this.error.message}),JSON.stringify(t)}}class Dr{constructor(t,e,n){this.targetId=t,this.state=e,this.error=n}static $s(t,e){const n=JSON.parse(e);let s,i=typeof n=="object"&&["not-current","current","rejected"].indexOf(n.state)!==-1&&(n.error===void 0||typeof n.error=="object");return i&&n.error&&(i=typeof n.error.message=="string"&&typeof n.error.code=="string",i&&(s=new C(n.error.code,n.error.message))),i?new Dr(t,n.state,s):(lt(Ht,`Failed to parse target state for ID '${t}': ${e}`),null)}Ws(){const t={state:this.state,updateTimeMs:Date.now()};return this.error&&(t.error={code:this.error.code,message:this.error.message}),JSON.stringify(t)}}class ii{constructor(t,e){this.clientId=t,this.activeTargetIds=e}static $s(t,e){const n=JSON.parse(e);let s=typeof n=="object"&&n.activeTargetIds instanceof Array,i=ca();for(let a=0;s&&a<n.activeTargetIds.length;++a)s=ih(n.activeTargetIds[a]),i=i.add(n.activeTargetIds[a]);return s?new ii(t,i):(lt(Ht,`Failed to parse client data for instance '${t}': ${e}`),null)}}class va{constructor(t,e){this.clientId=t,this.onlineState=e}static $s(t){const e=JSON.parse(t);return typeof e=="object"&&["Unknown","Online","Offline"].indexOf(e.onlineState)!==-1&&typeof e.clientId=="string"?new va(e.clientId,e.onlineState):(lt(Ht,`Failed to parse online state: ${t}`),null)}}class Go{constructor(){this.activeTargetIds=ca()}Qs(t){this.activeTargetIds=this.activeTargetIds.add(t)}Gs(t){this.activeTargetIds=this.activeTargetIds.delete(t)}Ws(){const t={activeTargetIds:this.activeTargetIds.toArray(),updateTimeMs:Date.now()};return JSON.stringify(t)}}class go{constructor(t,e,n,s,i){this.window=t,this.Ci=e,this.persistenceKey=n,this.zs=s,this.syncEngine=null,this.onlineStateHandler=null,this.sequenceNumberHandler=null,this.js=this.Js.bind(this),this.Hs=new nt(U),this.started=!1,this.Zs=[];const a=n.replace(/[.*+?^${}()|[\]\\]/g,"\\$&");this.storage=this.window.localStorage,this.currentUser=i,this.Xs=il(this.persistenceKey,this.zs),this.Ys=(function(l){return`firestore_sequence_number_${l}`})(this.persistenceKey),this.Hs=this.Hs.insert(this.zs,new Go),this.eo=new RegExp(`^${kd}_${a}_([^_]*)$`),this.no=new RegExp(`^${Md}_${a}_(\\d+)(?:_(.*))?$`),this.ro=new RegExp(`^${Od}_${a}_(\\d+)$`),this.io=(function(l){return`firestore_online_state_${l}`})(this.persistenceKey),this.so=(function(l){return`firestore_bundle_loaded_v2_${l}`})(this.persistenceKey),this.window.addEventListener("storage",this.js)}static v(t){return!(!t||!t.localStorage)}async start(){const t=await this.syncEngine.hs();for(const n of t){if(n===this.zs)continue;const s=this.getItem(il(this.persistenceKey,n));if(s){const i=ii.$s(n,s);i&&(this.Hs=this.Hs.insert(i.clientId,i))}}this.oo();const e=this.storage.getItem(this.io);if(e){const n=this._o(e);n&&this.ao(n)}for(const n of this.Zs)this.Js(n);this.Zs=[],this.window.addEventListener("pagehide",(()=>this.shutdown())),this.started=!0}writeSequenceNumber(t){this.setItem(this.Ys,JSON.stringify(t))}getAllActiveQueryTargets(){return this.uo(this.Hs)}isActiveQueryTarget(t){let e=!1;return this.Hs.forEach(((n,s)=>{s.activeTargetIds.has(t)&&(e=!0)})),e}addPendingMutation(t){this.co(t,"pending")}updateMutationState(t,e,n){this.co(t,e,n),this.lo(t)}addLocalQueryTarget(t,e=!0){let n="not-current";if(this.isActiveQueryTarget(t)){const s=this.storage.getItem(mo(this.persistenceKey,t));if(s){const i=Dr.$s(t,s);i&&(n=i.state)}}return e&&this.ho.Qs(t),this.oo(),n}removeLocalQueryTarget(t){this.ho.Gs(t),this.oo()}isLocalQueryTarget(t){return this.ho.activeTargetIds.has(t)}clearQueryState(t){this.removeItem(mo(this.persistenceKey,t))}updateQueryState(t,e,n){this.Po(t,e,n)}handleUserChange(t,e,n){e.forEach((s=>{this.lo(s)})),this.currentUser=t,n.forEach((s=>{this.addPendingMutation(s)}))}setOnlineState(t){this.To(t)}notifyBundleLoaded(t){this.Eo(t)}shutdown(){this.started&&(this.window.removeEventListener("storage",this.js),this.removeItem(this.Xs),this.started=!1)}getItem(t){const e=this.storage.getItem(t);return P(Ht,"READ",t,e),e}setItem(t,e){P(Ht,"SET",t,e),this.storage.setItem(t,e)}removeItem(t){P(Ht,"REMOVE",t),this.storage.removeItem(t)}Js(t){const e=t;if(e.storageArea===this.storage){if(P(Ht,"EVENT",e.key,e.newValue),e.key===this.Xs)return void lt("Received WebStorage notification for local change. Another client might have garbage-collected our state");this.Ci.enqueueRetryable((async()=>{if(this.started){if(e.key!==null){if(this.eo.test(e.key)){if(e.newValue==null){const n=this.Io(e.key);return this.Ro(n,null)}{const n=this.Ao(e.key,e.newValue);if(n)return this.Ro(n.clientId,n)}}else if(this.no.test(e.key)){if(e.newValue!==null){const n=this.Vo(e.key,e.newValue);if(n)return this.mo(n)}}else if(this.ro.test(e.key)){if(e.newValue!==null){const n=this.fo(e.key,e.newValue);if(n)return this.po(n)}}else if(e.key===this.io){if(e.newValue!==null){const n=this._o(e.newValue);if(n)return this.ao(n)}}else if(e.key===this.Ys){const n=(function(i){let a=Dt.ce;if(i!=null)try{const u=JSON.parse(i);L(typeof u=="number",30636,{yo:i}),a=u}catch(u){lt(Ht,"Failed to read sequence number from WebStorage",u)}return a})(e.newValue);n!==Dt.ce&&this.sequenceNumberHandler(n)}else if(e.key===this.so){const n=this.wo(e.newValue);await Promise.all(n.map((s=>this.syncEngine.So(s))))}}}else this.Zs.push(e)}))}}get ho(){return this.Hs.get(this.zs)}oo(){this.setItem(this.Xs,this.ho.Ws())}co(t,e,n){const s=new si(this.currentUser,t,e,n),i=ol(this.persistenceKey,this.currentUser,t);this.setItem(i,s.Ws())}lo(t){const e=ol(this.persistenceKey,this.currentUser,t);this.removeItem(e)}To(t){const e={clientId:this.zs,onlineState:t};this.storage.setItem(this.io,JSON.stringify(e))}Po(t,e,n){const s=mo(this.persistenceKey,t),i=new Dr(t,e,n);this.setItem(s,i.Ws())}Eo(t){const e=JSON.stringify(Array.from(t));this.setItem(this.so,e)}Io(t){const e=this.eo.exec(t);return e?e[1]:null}Ao(t,e){const n=this.Io(t);return ii.$s(n,e)}Vo(t,e){const n=this.no.exec(t),s=Number(n[1]),i=n[2]!==void 0?n[2]:null;return si.$s(new vt(i),s,e)}fo(t,e){const n=this.ro.exec(t),s=Number(n[1]);return Dr.$s(s,e)}_o(t){return va.$s(t)}wo(t){return JSON.parse(t)}async mo(t){if(t.user.uid===this.currentUser.uid)return this.syncEngine.bo(t.batchId,t.state,t.error);P(Ht,`Ignoring mutation for non-active user ${t.user.uid}`)}po(t){return this.syncEngine.Do(t.targetId,t.state,t.error)}Ro(t,e){const n=e?this.Hs.insert(t,e):this.Hs.remove(t),s=this.uo(this.Hs),i=this.uo(n),a=[],u=[];return i.forEach((l=>{s.has(l)||a.push(l)})),s.forEach((l=>{i.has(l)||u.push(l)})),this.syncEngine.Co(a,u).then((()=>{this.Hs=n}))}ao(t){this.Hs.get(t.clientId)&&this.onlineStateHandler(t.onlineState)}uo(t){let e=ca();return t.forEach(((n,s)=>{e=e.unionWith(s.activeTargetIds)})),e}}class Fd{constructor(){this.vo=new Go,this.Fo={},this.onlineStateHandler=null,this.sequenceNumberHandler=null}addPendingMutation(t){}updateMutationState(t,e,n){}addLocalQueryTarget(t,e=!0){return e&&this.vo.Qs(t),this.Fo[t]||"not-current"}updateQueryState(t,e,n){this.Fo[t]=e}removeLocalQueryTarget(t){this.vo.Gs(t)}isLocalQueryTarget(t){return this.vo.activeTargetIds.has(t)}clearQueryState(t){delete this.Fo[t]}getAllActiveQueryTargets(){return this.vo.activeTargetIds}isActiveQueryTarget(t){return this.vo.activeTargetIds.has(t)}start(){return this.vo=new Go,Promise.resolve()}handleUserChange(t,e,n){}setOnlineState(t){}shutdown(){}writeSequenceNumber(t){}notifyBundleLoaded(t){}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class L_{Mo(t){}shutdown(){}}/**
 * @license
 * Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const al="ConnectivityMonitor";class ul{constructor(){this.xo=()=>this.Oo(),this.No=()=>this.Bo(),this.Lo=[],this.ko()}Mo(t){this.Lo.push(t)}shutdown(){window.removeEventListener("online",this.xo),window.removeEventListener("offline",this.No)}ko(){window.addEventListener("online",this.xo),window.addEventListener("offline",this.No)}Oo(){P(al,"Network connectivity changed: AVAILABLE");for(const t of this.Lo)t(0)}Bo(){P(al,"Network connectivity changed: UNAVAILABLE");for(const t of this.Lo)t(1)}static v(){return typeof window<"u"&&window.addEventListener!==void 0&&window.removeEventListener!==void 0}}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */let Ss=null;function Ko(){return Ss===null?Ss=(function(){return 268435456+Math.round(2147483648*Math.random())})():Ss++,"0x"+Ss.toString(16)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const po="RestConnection",B_={BatchGetDocuments:"batchGet",Commit:"commit",RunQuery:"runQuery",RunAggregationQuery:"runAggregationQuery",ExecutePipeline:"executePipeline"};class U_{get qo(){return!1}constructor(t){this.databaseInfo=t,this.databaseId=t.databaseId;const e=t.ssl?"https":"http",n=encodeURIComponent(this.databaseId.projectId),s=encodeURIComponent(this.databaseId.database);this.Ko=e+"://"+t.host,this.Uo=`projects/${n}/databases/${s}`,this.$o=this.databaseId.database===Hs?`project_id=${n}`:`project_id=${n}&database_id=${s}`}Wo(t,e,n,s,i){const a=Ko(),u=this.Qo(t,e.toUriEncodedString());P(po,`Sending RPC '${t}' ${a}:`,u,n);const l={"google-cloud-resource-prefix":this.Uo,"x-goog-request-params":this.$o};this.Go(l,s,i);const{host:d}=new URL(u),f=Ll(d);return this.zo(t,u,l,n,f).then((g=>(P(po,`Received RPC '${t}' ${a}: `,g),g)),(g=>{throw vn(po,`RPC '${t}' ${a} failed with error: `,g,"url: ",u,"request:",n),g}))}jo(t,e,n,s,i,a){return this.Wo(t,e,n,s,i)}Go(t,e,n){t["X-Goog-Api-Client"]=(function(){return"gl-js/ fire/"+zn})(),t["Content-Type"]="text/plain",this.databaseInfo.appId&&(t["X-Firebase-GMPID"]=this.databaseInfo.appId),e&&e.headers.forEach(((s,i)=>t[i]=s)),n&&n.headers.forEach(((s,i)=>t[i]=s))}Qo(t,e){const n=B_[t];let s=`${this.Ko}/v1/${e}:${n}`;return this.databaseInfo.apiKey&&(s=`${s}?key=${encodeURIComponent(this.databaseInfo.apiKey)}`),s}terminate(){}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class q_{constructor(t){this.Jo=t.Jo,this.Ho=t.Ho}Zo(t){this.Xo=t}Yo(t){this.e_=t}t_(t){this.n_=t}onMessage(t){this.r_=t}close(){this.Ho()}send(t){this.Jo(t)}i_(){this.Xo()}s_(){this.e_()}o_(t){this.n_(t)}__(t){this.r_(t)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const wt="WebChannelConnection",pr=(r,t,e)=>{r.listen(t,(n=>{try{e(n)}catch(s){setTimeout((()=>{throw s}),0)}}))};class En extends U_{constructor(t){super(t),this.a_=[],this.forceLongPolling=t.forceLongPolling,this.autoDetectLongPolling=t.autoDetectLongPolling,this.useFetchStreams=t.useFetchStreams,this.longPollingOptions=t.longPollingOptions}static u_(){if(!En.c_){const t=Ql();pr(t,Hl.STAT_EVENT,(e=>{e.stat===Ao.PROXY?P(wt,"STAT_EVENT: detected buffering proxy"):e.stat===Ao.NOPROXY&&P(wt,"STAT_EVENT: detected no buffering proxy")})),En.c_=!0}}zo(t,e,n,s,i){const a=Ko();return new Promise(((u,l)=>{const d=new Gl;d.setWithCredentials(!0),d.listenOnce(Kl.COMPLETE,(()=>{try{switch(d.getLastErrorCode()){case Vs.NO_ERROR:const g=d.getResponseJson();P(wt,`XHR for RPC '${t}' ${a} received:`,JSON.stringify(g)),u(g);break;case Vs.TIMEOUT:P(wt,`RPC '${t}' ${a} timed out`),l(new C(S.DEADLINE_EXCEEDED,"Request time out"));break;case Vs.HTTP_ERROR:const E=d.getStatus();if(P(wt,`RPC '${t}' ${a} failed with status:`,E,"response text:",d.getResponseText()),E>0){let V=d.getResponseJson();Array.isArray(V)&&(V=V[0]);const D=V==null?void 0:V.error;if(D&&D.status&&D.message){const k=(function(K){const j=K.toLowerCase().replace(/_/g,"-");return Object.values(S).indexOf(j)>=0?j:S.UNKNOWN})(D.status);l(new C(k,D.message))}else l(new C(S.UNKNOWN,"Server responded with status "+d.getStatus()))}else l(new C(S.UNAVAILABLE,"Connection failed."));break;default:O(9055,{l_:t,streamId:a,h_:d.getLastErrorCode(),P_:d.getLastError()})}}finally{P(wt,`RPC '${t}' ${a} completed.`)}}));const f=JSON.stringify(s);P(wt,`RPC '${t}' ${a} sending request:`,s),d.send(e,"POST",f,n,15)}))}T_(t,e,n){const s=Ko(),i=[this.Ko,"/","google.firestore.v1.Firestore","/",t,"/channel"],a=this.createWebChannelTransport(),u={httpSessionIdParam:"gsessionid",initMessageHeaders:{},messageUrlParams:{database:`projects/${this.databaseId.projectId}/databases/${this.databaseId.database}`},sendRawJson:!0,supportsCrossDomainXhr:!0,internalChannelParams:{forwardChannelRequestTimeoutMs:6e5},forceLongPolling:this.forceLongPolling,detectBufferingProxy:this.autoDetectLongPolling},l=this.longPollingOptions.timeoutSeconds;l!==void 0&&(u.longPollingTimeout=Math.round(1e3*l)),this.useFetchStreams&&(u.useFetchStreams=!0),this.Go(u.initMessageHeaders,e,n),u.encodeInitMessageHeaders=!0;const d=i.join("");P(wt,`Creating RPC '${t}' stream ${s}: ${d}`,u);const f=a.createWebChannel(d,u);this.E_(f);let g=!1,E=!1;const V=new q_({Jo:D=>{E?P(wt,`Not sending because RPC '${t}' stream ${s} is closed:`,D):(g||(P(wt,`Opening RPC '${t}' stream ${s} transport.`),f.open(),g=!0),P(wt,`RPC '${t}' stream ${s} sending:`,D),f.send(D))},Ho:()=>f.close()});return pr(f,_r.EventType.OPEN,(()=>{E||(P(wt,`RPC '${t}' stream ${s} transport opened.`),V.i_())})),pr(f,_r.EventType.CLOSE,(()=>{E||(E=!0,P(wt,`RPC '${t}' stream ${s} transport closed`),V.o_(),this.I_(f))})),pr(f,_r.EventType.ERROR,(D=>{E||(E=!0,vn(wt,`RPC '${t}' stream ${s} transport errored. Name:`,D.name,"Message:",D.message),V.o_(new C(S.UNAVAILABLE,"The operation could not be completed")))})),pr(f,_r.EventType.MESSAGE,(D=>{var k;if(!E){const M=D.data[0];L(!!M,16349);const K=M,j=(K==null?void 0:K.error)||((k=K[0])==null?void 0:k.error);if(j){P(wt,`RPC '${t}' stream ${s} received error:`,j);const q=j.status;let rt=(function(I){const p=dt[I];if(p!==void 0)return Jh(p)})(q),W=j.message;q==="NOT_FOUND"&&W.includes("database")&&W.includes("does not exist")&&W.includes(this.databaseId.database)&&vn(`Database '${this.databaseId.database}' not found. Please check your project configuration.`),rt===void 0&&(rt=S.INTERNAL,W="Unknown error status: "+q+" with message "+j.message),E=!0,V.o_(new C(rt,W)),f.close()}else P(wt,`RPC '${t}' stream ${s} received:`,M),V.__(M)}})),En.u_(),setTimeout((()=>{V.s_()}),0),V}terminate(){this.a_.forEach((t=>t.close())),this.a_=[]}E_(t){this.a_.push(t)}I_(t){this.a_=this.a_.filter((e=>e===t))}Go(t,e,n){super.Go(t,e,n),this.databaseInfo.apiKey&&(t["x-goog-api-key"]=this.databaseInfo.apiKey)}createWebChannelTransport(){return Wl()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function j_(r){return new En(r)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Ld(){return typeof window<"u"?window:null}function Ls(){return typeof document<"u"?document:null}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function Ai(r){return new Qp(r,!0)}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */En.c_=!1;class Bd{constructor(t,e,n=1e3,s=1.5,i=6e4){this.Ci=t,this.timerId=e,this.R_=n,this.A_=s,this.V_=i,this.d_=0,this.m_=null,this.f_=Date.now(),this.reset()}reset(){this.d_=0}g_(){this.d_=this.V_}p_(t){this.cancel();const e=Math.floor(this.d_+this.y_()),n=Math.max(0,Date.now()-this.f_),s=Math.max(0,e-n);s>0&&P("ExponentialBackoff",`Backing off for ${s} ms (base delay: ${this.d_} ms, delay with jitter: ${e} ms, last attempt: ${n} ms ago)`),this.m_=this.Ci.enqueueAfterDelay(this.timerId,s,(()=>(this.f_=Date.now(),t()))),this.d_*=this.A_,this.d_<this.R_&&(this.d_=this.R_),this.d_>this.V_&&(this.d_=this.V_)}w_(){this.m_!==null&&(this.m_.skipDelay(),this.m_=null)}cancel(){this.m_!==null&&(this.m_.cancel(),this.m_=null)}y_(){return(Math.random()-.5)*this.d_}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const cl="PersistentStream";class Ud{constructor(t,e,n,s,i,a,u,l){this.Ci=t,this.S_=n,this.b_=s,this.connection=i,this.authCredentialsProvider=a,this.appCheckCredentialsProvider=u,this.listener=l,this.state=0,this.D_=0,this.C_=null,this.v_=null,this.stream=null,this.F_=0,this.M_=new Bd(t,e)}x_(){return this.state===1||this.state===5||this.O_()}O_(){return this.state===2||this.state===3}start(){this.F_=0,this.state!==4?this.auth():this.N_()}async stop(){this.x_()&&await this.close(0)}B_(){this.state=0,this.M_.reset()}L_(){this.O_()&&this.C_===null&&(this.C_=this.Ci.enqueueAfterDelay(this.S_,6e4,(()=>this.k_())))}q_(t){this.K_(),this.stream.send(t)}async k_(){if(this.O_())return this.close(0)}K_(){this.C_&&(this.C_.cancel(),this.C_=null)}U_(){this.v_&&(this.v_.cancel(),this.v_=null)}async close(t,e){this.K_(),this.U_(),this.M_.cancel(),this.D_++,t!==4?this.M_.reset():e&&e.code===S.RESOURCE_EXHAUSTED?(lt(e.toString()),lt("Using maximum backoff delay to prevent overloading the backend."),this.M_.g_()):e&&e.code===S.UNAUTHENTICATED&&this.state!==3&&(this.authCredentialsProvider.invalidateToken(),this.appCheckCredentialsProvider.invalidateToken()),this.stream!==null&&(this.W_(),this.stream.close(),this.stream=null),this.state=t,await this.listener.t_(e)}W_(){}auth(){this.state=1;const t=this.Q_(this.D_),e=this.D_;Promise.all([this.authCredentialsProvider.getToken(),this.appCheckCredentialsProvider.getToken()]).then((([n,s])=>{this.D_===e&&this.G_(n,s)}),(n=>{t((()=>{const s=new C(S.UNKNOWN,"Fetching auth token failed: "+n.message);return this.z_(s)}))}))}G_(t,e){const n=this.Q_(this.D_);this.stream=this.j_(t,e),this.stream.Zo((()=>{n((()=>this.listener.Zo()))})),this.stream.Yo((()=>{n((()=>(this.state=2,this.v_=this.Ci.enqueueAfterDelay(this.b_,1e4,(()=>(this.O_()&&(this.state=3),Promise.resolve()))),this.listener.Yo())))})),this.stream.t_((s=>{n((()=>this.z_(s)))})),this.stream.onMessage((s=>{n((()=>++this.F_==1?this.J_(s):this.onNext(s)))}))}N_(){this.state=5,this.M_.p_((async()=>{this.state=0,this.start()}))}z_(t){return P(cl,`close with error: ${t}`),this.stream=null,this.close(4,t)}Q_(t){return e=>{this.Ci.enqueueAndForget((()=>this.D_===t?e():(P(cl,"stream callback skipped by getCloseGuardedDispatcher."),Promise.resolve())))}}}class z_ extends Ud{constructor(t,e,n,s,i,a){super(t,"listen_stream_connection_backoff","listen_stream_idle","health_check_timeout",e,n,s,a),this.serializer=i}j_(t,e){return this.connection.T_("Listen",t,e)}J_(t){return this.onNext(t)}onNext(t){this.M_.reset();const e=Yp(this.serializer,t),n=(function(i){if(!("targetChange"in i))return B.min();const a=i.targetChange;return a.targetIds&&a.targetIds.length?B.min():a.readTime?Pt(a.readTime):B.min()})(t);return this.listener.H_(e,n)}Z_(t){const e={};e.database=Uo(this.serializer),e.addTarget=(function(i,a){let u;const l=a.target;if(u=Qs(l)?{documents:sd(i,l)}:{query:id(i,l).ft},u.targetId=a.targetId,a.resumeToken.approximateByteSize()>0){u.resumeToken=Zh(i,a.resumeToken);const d=Lo(i,a.expectedCount);d!==null&&(u.expectedCount=d)}else if(a.snapshotVersion.compareTo(B.min())>0){u.readTime=Fn(i,a.snapshotVersion.toTimestamp());const d=Lo(i,a.expectedCount);d!==null&&(u.expectedCount=d)}return u})(this.serializer,t);const n=Zp(this.serializer,t);n&&(e.labels=n),this.q_(e)}X_(t){const e={};e.database=Uo(this.serializer),e.removeTarget=t,this.q_(e)}}class $_ extends Ud{constructor(t,e,n,s,i,a){super(t,"write_stream_connection_backoff","write_stream_idle","health_check_timeout",e,n,s,a),this.serializer=i}get Y_(){return this.F_>0}start(){this.lastStreamToken=void 0,super.start()}W_(){this.Y_&&this.ea([])}j_(t,e){return this.connection.T_("Write",t,e)}J_(t){return L(!!t.streamToken,31322),this.lastStreamToken=t.streamToken,L(!t.writeResults||t.writeResults.length===0,55816),this.listener.ta()}onNext(t){L(!!t.streamToken,12678),this.lastStreamToken=t.streamToken,this.M_.reset();const e=Xp(t.writeResults,t.commitTime),n=Pt(t.commitTime);return this.listener.na(n,e)}ra(){const t={};t.database=Uo(this.serializer),this.q_(t)}ea(t){const e={streamToken:this.lastStreamToken,writes:t.map((n=>Ys(this.serializer,n)))};this.q_(e)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class G_{}class K_ extends G_{constructor(t,e,n,s){super(),this.authCredentials=t,this.appCheckCredentials=e,this.connection=n,this.serializer=s,this.ia=!1}sa(){if(this.ia)throw new C(S.FAILED_PRECONDITION,"The client has already been terminated.")}Wo(t,e,n,s){return this.sa(),Promise.all([this.authCredentials.getToken(),this.appCheckCredentials.getToken()]).then((([i,a])=>this.connection.Wo(t,Bo(e,n),s,i,a))).catch((i=>{throw i.name==="FirebaseError"?(i.code===S.UNAUTHENTICATED&&(this.authCredentials.invalidateToken(),this.appCheckCredentials.invalidateToken()),i):new C(S.UNKNOWN,i.toString())}))}jo(t,e,n,s,i){return this.sa(),Promise.all([this.authCredentials.getToken(),this.appCheckCredentials.getToken()]).then((([a,u])=>this.connection.jo(t,Bo(e,n),s,a,u,i))).catch((a=>{throw a.name==="FirebaseError"?(a.code===S.UNAUTHENTICATED&&(this.authCredentials.invalidateToken(),this.appCheckCredentials.invalidateToken()),a):new C(S.UNKNOWN,a.toString())}))}terminate(){this.ia=!0,this.connection.terminate()}}function H_(r,t,e,n){return new K_(r,t,e,n)}class Q_{constructor(t,e){this.asyncQueue=t,this.onlineStateHandler=e,this.state="Unknown",this.oa=0,this._a=null,this.aa=!0}ua(){this.oa===0&&(this.ca("Unknown"),this._a=this.asyncQueue.enqueueAfterDelay("online_state_timeout",1e4,(()=>(this._a=null,this.la("Backend didn't respond within 10 seconds."),this.ca("Offline"),Promise.resolve()))))}ha(t){this.state==="Online"?this.ca("Unknown"):(this.oa++,this.oa>=1&&(this.Pa(),this.la(`Connection failed 1 times. Most recent error: ${t.toString()}`),this.ca("Offline")))}set(t){this.Pa(),this.oa=0,t==="Online"&&(this.aa=!1),this.ca(t)}ca(t){t!==this.state&&(this.state=t,this.onlineStateHandler(t))}la(t){const e=`Could not reach Cloud Firestore backend. ${t}
This typically indicates that your device does not have a healthy Internet connection at the moment. The client will operate in offline mode until it is able to successfully connect to the backend.`;this.aa?(lt(e),this.aa=!1):P("OnlineStateTracker",e)}Pa(){this._a!==null&&(this._a.cancel(),this._a=null)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const nn="RemoteStore";class W_{constructor(t,e,n,s,i){this.localStore=t,this.datastore=e,this.asyncQueue=n,this.remoteSyncer={},this.Ta=[],this.Ea=new Map,this.Ia=new Set,this.Ra=[],this.Aa=i,this.Aa.Mo((a=>{n.enqueueAndForget((async()=>{sn(this)&&(P(nn,"Restarting streams for network reachability change."),await(async function(l){const d=F(l);d.Ia.add(4),await es(d),d.Va.set("Unknown"),d.Ia.delete(4),await bi(d)})(this))}))})),this.Va=new Q_(n,s)}}async function bi(r){if(sn(r))for(const t of r.Ra)await t(!0)}async function es(r){for(const t of r.Ra)await t(!1)}function Ri(r,t){const e=F(r);e.Ea.has(t.targetId)||(e.Ea.set(t.targetId,t),Ra(e)?ba(e):Hn(e).O_()&&Aa(e,t))}function Bn(r,t){const e=F(r),n=Hn(e);e.Ea.delete(t),n.O_()&&qd(e,t),e.Ea.size===0&&(n.O_()?n.L_():sn(e)&&e.Va.set("Unknown"))}function Aa(r,t){if(r.da.$e(t.targetId),t.resumeToken.approximateByteSize()>0||t.snapshotVersion.compareTo(B.min())>0){const e=r.remoteSyncer.getRemoteKeysForTarget(t.targetId).size;t=t.withExpectedCount(e)}Hn(r).Z_(t)}function qd(r,t){r.da.$e(t),Hn(r).X_(t)}function ba(r){r.da=new $p({getRemoteKeysForTarget:t=>r.remoteSyncer.getRemoteKeysForTarget(t),At:t=>r.Ea.get(t)||null,ht:()=>r.datastore.serializer.databaseId}),Hn(r).start(),r.Va.ua()}function Ra(r){return sn(r)&&!Hn(r).x_()&&r.Ea.size>0}function sn(r){return F(r).Ia.size===0}function jd(r){r.da=void 0}async function J_(r){r.Va.set("Online")}async function Y_(r){r.Ea.forEach(((t,e)=>{Aa(r,t)}))}async function X_(r,t){jd(r),Ra(r)?(r.Va.ha(t),ba(r)):r.Va.set("Unknown")}async function Z_(r,t,e){if(r.Va.set("Online"),t instanceof Xh&&t.state===2&&t.cause)try{await(async function(s,i){const a=i.cause;for(const u of i.targetIds)s.Ea.has(u)&&(await s.remoteSyncer.rejectListen(u,a),s.Ea.delete(u),s.da.removeTarget(u))})(r,t)}catch(n){P(nn,"Failed to remove targets %s: %s ",t.targetIds.join(","),n),await oi(r,n)}else if(t instanceof Os?r.da.Xe(t):t instanceof Yh?r.da.st(t):r.da.tt(t),!e.isEqual(B.min()))try{const n=await Cd(r.localStore);e.compareTo(n)>=0&&await(function(i,a){const u=i.da.Tt(a);return u.targetChanges.forEach(((l,d)=>{if(l.resumeToken.approximateByteSize()>0){const f=i.Ea.get(d);f&&i.Ea.set(d,f.withResumeToken(l.resumeToken,a))}})),u.targetMismatches.forEach(((l,d)=>{const f=i.Ea.get(l);if(!f)return;i.Ea.set(l,f.withResumeToken(ht.EMPTY_BYTE_STRING,f.snapshotVersion)),qd(i,l);const g=new Zt(f.target,l,d,f.sequenceNumber);Aa(i,g)})),i.remoteSyncer.applyRemoteEvent(u)})(r,e)}catch(n){P(nn,"Failed to raise snapshot:",n),await oi(r,n)}}async function oi(r,t,e){if(!Se(t))throw t;r.Ia.add(1),await es(r),r.Va.set("Offline"),e||(e=()=>Cd(r.localStore)),r.asyncQueue.enqueueRetryable((async()=>{P(nn,"Retrying IndexedDB access"),await e(),r.Ia.delete(1),await bi(r)}))}function zd(r,t){return t().catch((e=>oi(r,e,t)))}async function Kn(r){const t=F(r),e=Ae(t);let n=t.Ta.length>0?t.Ta[t.Ta.length-1].batchId:Ke;for(;ty(t);)try{const s=await F_(t.localStore,n);if(s===null){t.Ta.length===0&&e.L_();break}n=s.batchId,ey(t,s)}catch(s){await oi(t,s)}$d(t)&&Gd(t)}function ty(r){return sn(r)&&r.Ta.length<10}function ey(r,t){r.Ta.push(t);const e=Ae(r);e.O_()&&e.Y_&&e.ea(t.mutations)}function $d(r){return sn(r)&&!Ae(r).x_()&&r.Ta.length>0}function Gd(r){Ae(r).start()}async function ny(r){Ae(r).ra()}async function ry(r){const t=Ae(r);for(const e of r.Ta)t.ea(e.mutations)}async function sy(r,t,e){const n=r.Ta.shift(),s=da.from(n,t,e);await zd(r,(()=>r.remoteSyncer.applySuccessfulWrite(s))),await Kn(r)}async function iy(r,t){t&&Ae(r).Y_&&await(async function(n,s){if((function(a){return qp(a)&&a!==S.ABORTED})(s.code)){const i=n.Ta.shift();Ae(n).B_(),await zd(n,(()=>n.remoteSyncer.rejectFailedWrite(i.batchId,s))),await Kn(n)}})(r,t),$d(r)&&Gd(r)}async function ll(r,t){const e=F(r);e.asyncQueue.verifyOperationInProgress(),P(nn,"RemoteStore received new credentials");const n=sn(e);e.Ia.add(3),await es(e),n&&e.Va.set("Unknown"),await e.remoteSyncer.handleCredentialChange(t),e.Ia.delete(3),await bi(e)}async function Ho(r,t){const e=F(r);t?(e.Ia.delete(2),await bi(e)):t||(e.Ia.add(2),await es(e),e.Va.set("Unknown"))}function Hn(r){return r.ma||(r.ma=(function(e,n,s){const i=F(e);return i.sa(),new z_(n,i.connection,i.authCredentials,i.appCheckCredentials,i.serializer,s)})(r.datastore,r.asyncQueue,{Zo:J_.bind(null,r),Yo:Y_.bind(null,r),t_:X_.bind(null,r),H_:Z_.bind(null,r)}),r.Ra.push((async t=>{t?(r.ma.B_(),Ra(r)?ba(r):r.Va.set("Unknown")):(await r.ma.stop(),jd(r))}))),r.ma}function Ae(r){return r.fa||(r.fa=(function(e,n,s){const i=F(e);return i.sa(),new $_(n,i.connection,i.authCredentials,i.appCheckCredentials,i.serializer,s)})(r.datastore,r.asyncQueue,{Zo:()=>Promise.resolve(),Yo:ny.bind(null,r),t_:iy.bind(null,r),ta:ry.bind(null,r),na:sy.bind(null,r)}),r.Ra.push((async t=>{t?(r.fa.B_(),await Kn(r)):(await r.fa.stop(),r.Ta.length>0&&(P(nn,`Stopping write stream with ${r.Ta.length} pending writes`),r.Ta=[]))}))),r.fa}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Sa{constructor(t,e,n,s,i){this.asyncQueue=t,this.timerId=e,this.targetTimeMs=n,this.op=s,this.removalCallback=i,this.deferred=new jt,this.then=this.deferred.promise.then.bind(this.deferred.promise),this.deferred.promise.catch((a=>{}))}get promise(){return this.deferred.promise}static createAndSchedule(t,e,n,s,i){const a=Date.now()+n,u=new Sa(t,e,a,s,i);return u.start(n),u}start(t){this.timerHandle=setTimeout((()=>this.handleDelayElapsed()),t)}skipDelay(){return this.handleDelayElapsed()}cancel(t){this.timerHandle!==null&&(this.clearTimeout(),this.deferred.reject(new C(S.CANCELLED,"Operation cancelled"+(t?": "+t:""))))}handleDelayElapsed(){this.asyncQueue.enqueueAndForget((()=>this.timerHandle!==null?(this.clearTimeout(),this.op().then((t=>this.deferred.resolve(t)))):Promise.resolve()))}clearTimeout(){this.timerHandle!==null&&(this.removalCallback(this),clearTimeout(this.timerHandle),this.timerHandle=null)}}function Si(r,t){if(lt("AsyncQueue",`${t}: ${r}`),Se(r))return new C(S.UNAVAILABLE,`${t}: ${r}`);throw r}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Tn{static emptySet(t){return new Tn(t.comparator)}constructor(t){this.comparator=t?(e,n)=>t(e,n)||N.comparator(e.key,n.key):(e,n)=>N.comparator(e.key,n.key),this.keyedMap=yr(),this.sortedSet=new nt(this.comparator)}has(t){return this.keyedMap.get(t)!=null}get(t){return this.keyedMap.get(t)}first(){return this.sortedSet.minKey()}last(){return this.sortedSet.maxKey()}isEmpty(){return this.sortedSet.isEmpty()}indexOf(t){const e=this.keyedMap.get(t);return e?this.sortedSet.indexOf(e):-1}get size(){return this.sortedSet.size}forEach(t){this.sortedSet.inorderTraversal(((e,n)=>(t(e),!1)))}add(t){const e=this.delete(t.key);return e.copy(e.keyedMap.insert(t.key,t),e.sortedSet.insert(t,null))}delete(t){const e=this.get(t);return e?this.copy(this.keyedMap.remove(t),this.sortedSet.remove(e)):this}isEqual(t){if(!(t instanceof Tn)||this.size!==t.size)return!1;const e=this.sortedSet.getIterator(),n=t.sortedSet.getIterator();for(;e.hasNext();){const s=e.getNext().key,i=n.getNext().key;if(!s.isEqual(i))return!1}return!0}toString(){const t=[];return this.forEach((e=>{t.push(e.toString())})),t.length===0?"DocumentSet ()":`DocumentSet (
  `+t.join(`  
`)+`
)`}copy(t,e){const n=new Tn;return n.comparator=this.comparator,n.keyedMap=t,n.sortedSet=e,n}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class hl{constructor(){this.ga=new nt(N.comparator)}track(t){const e=t.doc.key,n=this.ga.get(e);n?t.type!==0&&n.type===3?this.ga=this.ga.insert(e,t):t.type===3&&n.type!==1?this.ga=this.ga.insert(e,{type:n.type,doc:t.doc}):t.type===2&&n.type===2?this.ga=this.ga.insert(e,{type:2,doc:t.doc}):t.type===2&&n.type===0?this.ga=this.ga.insert(e,{type:0,doc:t.doc}):t.type===1&&n.type===0?this.ga=this.ga.remove(e):t.type===1&&n.type===2?this.ga=this.ga.insert(e,{type:1,doc:n.doc}):t.type===0&&n.type===1?this.ga=this.ga.insert(e,{type:2,doc:t.doc}):O(63341,{Vt:t,pa:n}):this.ga=this.ga.insert(e,t)}ya(){const t=[];return this.ga.inorderTraversal(((e,n)=>{t.push(n)})),t}}class Un{constructor(t,e,n,s,i,a,u,l,d){this.query=t,this.docs=e,this.oldDocs=n,this.docChanges=s,this.mutatedKeys=i,this.fromCache=a,this.syncStateChanged=u,this.excludesMetadataChanges=l,this.hasCachedResults=d}static fromInitialDocuments(t,e,n,s,i){const a=[];return e.forEach((u=>{a.push({type:0,doc:u})})),new Un(t,e,Tn.emptySet(e),a,n,s,!0,!1,i)}get hasPendingWrites(){return!this.mutatedKeys.isEmpty()}isEqual(t){if(!(this.fromCache===t.fromCache&&this.hasCachedResults===t.hasCachedResults&&this.syncStateChanged===t.syncStateChanged&&this.mutatedKeys.isEqual(t.mutatedKeys)&&yi(this.query,t.query)&&this.docs.isEqual(t.docs)&&this.oldDocs.isEqual(t.oldDocs)))return!1;const e=this.docChanges,n=t.docChanges;if(e.length!==n.length)return!1;for(let s=0;s<e.length;s++)if(e[s].type!==n[s].type||!e[s].doc.isEqual(n[s].doc))return!1;return!0}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class oy{constructor(){this.wa=void 0,this.Sa=[]}ba(){return this.Sa.some((t=>t.Da()))}}class ay{constructor(){this.queries=dl(),this.onlineState="Unknown",this.Ca=new Set}terminate(){(function(e,n){const s=F(e),i=s.queries;s.queries=dl(),i.forEach(((a,u)=>{for(const l of u.Sa)l.onError(n)}))})(this,new C(S.ABORTED,"Firestore shutting down"))}}function dl(){return new se((r=>Mh(r)),yi)}async function Va(r,t){const e=F(r);let n=3;const s=t.query;let i=e.queries.get(s);i?!i.ba()&&t.Da()&&(n=2):(i=new oy,n=t.Da()?0:1);try{switch(n){case 0:i.wa=await e.onListen(s,!0);break;case 1:i.wa=await e.onListen(s,!1);break;case 2:await e.onFirstRemoteStoreListen(s)}}catch(a){const u=Si(a,`Initialization of query '${pn(t.query)}' failed`);return void t.onError(u)}e.queries.set(s,i),i.Sa.push(t),t.va(e.onlineState),i.wa&&t.Fa(i.wa)&&Ca(e)}async function Pa(r,t){const e=F(r),n=t.query;let s=3;const i=e.queries.get(n);if(i){const a=i.Sa.indexOf(t);a>=0&&(i.Sa.splice(a,1),i.Sa.length===0?s=t.Da()?0:1:!i.ba()&&t.Da()&&(s=2))}switch(s){case 0:return e.queries.delete(n),e.onUnlisten(n,!0);case 1:return e.queries.delete(n),e.onUnlisten(n,!1);case 2:return e.onLastRemoteStoreUnlisten(n);default:return}}function uy(r,t){const e=F(r);let n=!1;for(const s of t){const i=s.query,a=e.queries.get(i);if(a){for(const u of a.Sa)u.Fa(s)&&(n=!0);a.wa=s}}n&&Ca(e)}function cy(r,t,e){const n=F(r),s=n.queries.get(t);if(s)for(const i of s.Sa)i.onError(e);n.queries.delete(t)}function Ca(r){r.Ca.forEach((t=>{t.next()}))}var Qo,fl;(fl=Qo||(Qo={})).Ma="default",fl.Cache="cache";class Da{constructor(t,e,n){this.query=t,this.xa=e,this.Oa=!1,this.Na=null,this.onlineState="Unknown",this.options=n||{}}Fa(t){if(!this.options.includeMetadataChanges){const n=[];for(const s of t.docChanges)s.type!==3&&n.push(s);t=new Un(t.query,t.docs,t.oldDocs,n,t.mutatedKeys,t.fromCache,t.syncStateChanged,!0,t.hasCachedResults)}let e=!1;return this.Oa?this.Ba(t)&&(this.xa.next(t),e=!0):this.La(t,this.onlineState)&&(this.ka(t),e=!0),this.Na=t,e}onError(t){this.xa.error(t)}va(t){this.onlineState=t;let e=!1;return this.Na&&!this.Oa&&this.La(this.Na,t)&&(this.ka(this.Na),e=!0),e}La(t,e){if(!t.fromCache||!this.Da())return!0;const n=e!=="Offline";return(!this.options.qa||!n)&&(!t.docs.isEmpty()||t.hasCachedResults||e==="Offline")}Ba(t){if(t.docChanges.length>0)return!0;const e=this.Na&&this.Na.hasPendingWrites!==t.hasPendingWrites;return!(!t.syncStateChanged&&!e)&&this.options.includeMetadataChanges===!0}ka(t){t=Un.fromInitialDocuments(t.query,t.docs,t.mutatedKeys,t.fromCache,t.hasCachedResults),this.Oa=!0,this.xa.next(t)}Da(){return this.options.source!==Qo.Cache}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Kd{constructor(t){this.key=t}}class Hd{constructor(t){this.key=t}}class Qd{constructor(t,e){this.query=t,this.Za=e,this.Xa=null,this.hasCachedResults=!1,this.current=!1,this.Ya=$(),this.mutatedKeys=$(),this.eu=Fh(t),this.tu=new Tn(this.eu)}get nu(){return this.Za}ru(t,e){const n=e?e.iu:new hl,s=e?e.tu:this.tu;let i=e?e.mutatedKeys:this.mutatedKeys,a=s,u=!1;const l=this.query.limitType==="F"&&s.size===this.query.limit?s.last():null,d=this.query.limitType==="L"&&s.size===this.query.limit?s.first():null;if(t.inorderTraversal(((f,g)=>{const E=s.get(f),V=Yr(this.query,g)?g:null,D=!!E&&this.mutatedKeys.has(E.key),k=!!V&&(V.hasLocalMutations||this.mutatedKeys.has(V.key)&&V.hasCommittedMutations);let M=!1;E&&V?E.data.isEqual(V.data)?D!==k&&(n.track({type:3,doc:V}),M=!0):this.su(E,V)||(n.track({type:2,doc:V}),M=!0,(l&&this.eu(V,l)>0||d&&this.eu(V,d)<0)&&(u=!0)):!E&&V?(n.track({type:0,doc:V}),M=!0):E&&!V&&(n.track({type:1,doc:E}),M=!0,(l||d)&&(u=!0)),M&&(V?(a=a.add(V),i=k?i.add(f):i.delete(f)):(a=a.delete(f),i=i.delete(f)))})),this.query.limit!==null)for(;a.size>this.query.limit;){const f=this.query.limitType==="F"?a.last():a.first();a=a.delete(f.key),i=i.delete(f.key),n.track({type:1,doc:f})}return{tu:a,iu:n,bs:u,mutatedKeys:i}}su(t,e){return t.hasLocalMutations&&e.hasCommittedMutations&&!e.hasLocalMutations}applyChanges(t,e,n,s){const i=this.tu;this.tu=t.tu,this.mutatedKeys=t.mutatedKeys;const a=t.iu.ya();a.sort(((f,g)=>(function(V,D){const k=M=>{switch(M){case 0:return 1;case 2:case 3:return 2;case 1:return 0;default:return O(20277,{Vt:M})}};return k(V)-k(D)})(f.type,g.type)||this.eu(f.doc,g.doc))),this.ou(n),s=s??!1;const u=e&&!s?this._u():[],l=this.Ya.size===0&&this.current&&!s?1:0,d=l!==this.Xa;return this.Xa=l,a.length!==0||d?{snapshot:new Un(this.query,t.tu,i,a,t.mutatedKeys,l===0,d,!1,!!n&&n.resumeToken.approximateByteSize()>0),au:u}:{au:u}}va(t){return this.current&&t==="Offline"?(this.current=!1,this.applyChanges({tu:this.tu,iu:new hl,mutatedKeys:this.mutatedKeys,bs:!1},!1)):{au:[]}}uu(t){return!this.Za.has(t)&&!!this.tu.has(t)&&!this.tu.get(t).hasLocalMutations}ou(t){t&&(t.addedDocuments.forEach((e=>this.Za=this.Za.add(e))),t.modifiedDocuments.forEach((e=>{})),t.removedDocuments.forEach((e=>this.Za=this.Za.delete(e))),this.current=t.current)}_u(){if(!this.current)return[];const t=this.Ya;this.Ya=$(),this.tu.forEach((n=>{this.uu(n.key)&&(this.Ya=this.Ya.add(n.key))}));const e=[];return t.forEach((n=>{this.Ya.has(n)||e.push(new Hd(n))})),this.Ya.forEach((n=>{t.has(n)||e.push(new Kd(n))})),e}cu(t){this.Za=t.ks,this.Ya=$();const e=this.ru(t.documents);return this.applyChanges(e,!0)}lu(){return Un.fromInitialDocuments(this.query,this.tu,this.mutatedKeys,this.Xa===0,this.hasCachedResults)}}const Qn="SyncEngine";class ly{constructor(t,e,n){this.query=t,this.targetId=e,this.view=n}}class hy{constructor(t){this.key=t,this.hu=!1}}class dy{constructor(t,e,n,s,i,a){this.localStore=t,this.remoteStore=e,this.eventManager=n,this.sharedClientState=s,this.currentUser=i,this.maxConcurrentLimboResolutions=a,this.Pu={},this.Tu=new se((u=>Mh(u)),yi),this.Eu=new Map,this.Iu=new Set,this.Ru=new nt(N.comparator),this.Au=new Map,this.Vu=new ya,this.du={},this.mu=new Map,this.fu=en.ar(),this.onlineState="Unknown",this.gu=void 0}get isPrimaryClient(){return this.gu===!0}}async function fy(r,t,e=!0){const n=Vi(r);let s;const i=n.Tu.get(t);return i?(n.sharedClientState.addLocalQueryTarget(i.targetId),s=i.view.lu()):s=await Wd(n,t,e,!0),s}async function my(r,t){const e=Vi(r);await Wd(e,t,!0,!1)}async function Wd(r,t,e,n){const s=await ni(r.localStore,Ot(t)),i=s.targetId,a=r.sharedClientState.addLocalQueryTarget(i,e);let u;return n&&(u=await xa(r,t,i,a==="current",s.resumeToken)),r.isPrimaryClient&&e&&Ri(r.remoteStore,s),u}async function xa(r,t,e,n,s){r.pu=(g,E,V)=>(async function(k,M,K,j){let q=M.view.ru(K);q.bs&&(q=await ri(k.localStore,M.query,!1).then((({documents:I})=>M.view.ru(I,q))));const rt=j&&j.targetChanges.get(M.targetId),W=j&&j.targetMismatches.get(M.targetId)!=null,J=M.view.applyChanges(q,k.isPrimaryClient,rt,W);return Wo(k,M.targetId,J.au),J.snapshot})(r,g,E,V);const i=await ri(r.localStore,t,!0),a=new Qd(t,i.ks),u=a.ru(i.documents),l=ts.createSynthesizedTargetChangeForCurrentChange(e,n&&r.onlineState!=="Offline",s),d=a.applyChanges(u,r.isPrimaryClient,l);Wo(r,e,d.au);const f=new ly(t,e,a);return r.Tu.set(t,f),r.Eu.has(e)?r.Eu.get(e).push(t):r.Eu.set(e,[t]),d.snapshot}async function gy(r,t,e){const n=F(r),s=n.Tu.get(t),i=n.Eu.get(s.targetId);if(i.length>1)return n.Eu.set(s.targetId,i.filter((a=>!yi(a,t)))),void n.Tu.delete(t);n.isPrimaryClient?(n.sharedClientState.removeLocalQueryTarget(s.targetId),n.sharedClientState.isActiveQueryTarget(s.targetId)||await Ln(n.localStore,s.targetId,!1).then((()=>{n.sharedClientState.clearQueryState(s.targetId),e&&Bn(n.remoteStore,s.targetId),qn(n,s.targetId)})).catch(Re)):(qn(n,s.targetId),await Ln(n.localStore,s.targetId,!0))}async function py(r,t){const e=F(r),n=e.Tu.get(t),s=e.Eu.get(n.targetId);e.isPrimaryClient&&s.length===1&&(e.sharedClientState.removeLocalQueryTarget(n.targetId),Bn(e.remoteStore,n.targetId))}async function _y(r,t,e){const n=Oa(r);try{const s=await(function(a,u){const l=F(a),d=X.now(),f=u.reduce(((V,D)=>V.add(D.key)),$());let g,E;return l.persistence.runTransaction("Locally write mutations","readwrite",(V=>{let D=Mt(),k=$();return l.xs.getEntries(V,f).next((M=>{D=M,D.forEach(((K,j)=>{j.isValidDocument()||(k=k.add(K))}))})).next((()=>l.localDocuments.getOverlayedDocuments(V,D))).next((M=>{g=M;const K=[];for(const j of u){const q=Bp(j,g.get(j.key).overlayedDocument);q!=null&&K.push(new ie(j.key,q,bh(q.value.mapValue),pt.exists(!0)))}return l.mutationQueue.addMutationBatch(V,d,K,u)})).next((M=>{E=M;const K=M.applyToLocalDocumentSet(g,k);return l.documentOverlayCache.saveOverlays(V,M.batchId,K)}))})).then((()=>({batchId:E.batchId,changes:Bh(g)})))})(n.localStore,t);n.sharedClientState.addPendingMutation(s.batchId),(function(a,u,l){let d=a.du[a.currentUser.toKey()];d||(d=new nt(U)),d=d.insert(u,l),a.du[a.currentUser.toKey()]=d})(n,s.batchId,e),await Pe(n,s.changes),await Kn(n.remoteStore)}catch(s){const i=Si(s,"Failed to persist write");e.reject(i)}}async function Jd(r,t){const e=F(r);try{const n=await M_(e.localStore,t);t.targetChanges.forEach(((s,i)=>{const a=e.Au.get(i);a&&(L(s.addedDocuments.size+s.modifiedDocuments.size+s.removedDocuments.size<=1,22616),s.addedDocuments.size>0?a.hu=!0:s.modifiedDocuments.size>0?L(a.hu,14607):s.removedDocuments.size>0&&(L(a.hu,42227),a.hu=!1))})),await Pe(e,n,t)}catch(n){await Re(n)}}function ml(r,t,e){const n=F(r);if(n.isPrimaryClient&&e===0||!n.isPrimaryClient&&e===1){const s=[];n.Tu.forEach(((i,a)=>{const u=a.view.va(t);u.snapshot&&s.push(u.snapshot)})),(function(a,u){const l=F(a);l.onlineState=u;let d=!1;l.queries.forEach(((f,g)=>{for(const E of g.Sa)E.va(u)&&(d=!0)})),d&&Ca(l)})(n.eventManager,t),s.length&&n.Pu.H_(s),n.onlineState=t,n.isPrimaryClient&&n.sharedClientState.setOnlineState(t)}}async function yy(r,t,e){const n=F(r);n.sharedClientState.updateQueryState(t,"rejected",e);const s=n.Au.get(t),i=s&&s.key;if(i){let a=new nt(N.comparator);a=a.insert(i,ct.newNoDocument(i,B.min()));const u=$().add(i),l=new Zr(B.min(),new Map,new nt(U),a,u);await Jd(n,l),n.Ru=n.Ru.remove(i),n.Au.delete(t),Ma(n)}else await Ln(n.localStore,t,!1).then((()=>qn(n,t,e))).catch(Re)}async function Iy(r,t){const e=F(r),n=t.batch.batchId;try{const s=await k_(e.localStore,t);ka(e,n,null),Na(e,n),e.sharedClientState.updateMutationState(n,"acknowledged"),await Pe(e,s)}catch(s){await Re(s)}}async function Ey(r,t,e){const n=F(r);try{const s=await(function(a,u){const l=F(a);return l.persistence.runTransaction("Reject batch","readwrite-primary",(d=>{let f;return l.mutationQueue.lookupMutationBatch(d,u).next((g=>(L(g!==null,37113),f=g.keys(),l.mutationQueue.removeMutationBatch(d,g)))).next((()=>l.mutationQueue.performConsistencyCheck(d))).next((()=>l.documentOverlayCache.removeOverlaysForBatchId(d,f,u))).next((()=>l.localDocuments.recalculateAndSaveOverlaysForDocumentKeys(d,f))).next((()=>l.localDocuments.getDocuments(d,f)))}))})(n.localStore,t);ka(n,t,e),Na(n,t),n.sharedClientState.updateMutationState(t,"rejected",e),await Pe(n,s)}catch(s){await Re(s)}}function Na(r,t){(r.mu.get(t)||[]).forEach((e=>{e.resolve()})),r.mu.delete(t)}function ka(r,t,e){const n=F(r);let s=n.du[n.currentUser.toKey()];if(s){const i=s.get(t);i&&(e?i.reject(e):i.resolve(),s=s.remove(t)),n.du[n.currentUser.toKey()]=s}}function qn(r,t,e=null){r.sharedClientState.removeLocalQueryTarget(t);for(const n of r.Eu.get(t))r.Tu.delete(n),e&&r.Pu.yu(n,e);r.Eu.delete(t),r.isPrimaryClient&&r.Vu.Gr(t).forEach((n=>{r.Vu.containsKey(n)||Yd(r,n)}))}function Yd(r,t){r.Iu.delete(t.path.canonicalString());const e=r.Ru.get(t);e!==null&&(Bn(r.remoteStore,e),r.Ru=r.Ru.remove(t),r.Au.delete(e),Ma(r))}function Wo(r,t,e){for(const n of e)n instanceof Kd?(r.Vu.addReference(n.key,t),Ty(r,n)):n instanceof Hd?(P(Qn,"Document no longer in limbo: "+n.key),r.Vu.removeReference(n.key,t),r.Vu.containsKey(n.key)||Yd(r,n.key)):O(19791,{wu:n})}function Ty(r,t){const e=t.key,n=e.path.canonicalString();r.Ru.get(e)||r.Iu.has(n)||(P(Qn,"New document in limbo: "+e),r.Iu.add(n),Ma(r))}function Ma(r){for(;r.Iu.size>0&&r.Ru.size<r.maxConcurrentLimboResolutions;){const t=r.Iu.values().next().value;r.Iu.delete(t);const e=new N(Y.fromString(t)),n=r.fu.next();r.Au.set(n,new hy(e)),r.Ru=r.Ru.insert(e,n),Ri(r.remoteStore,new Zt(Ot(Jr(e.path)),n,"TargetPurposeLimboResolution",Dt.ce))}}async function Pe(r,t,e){const n=F(r),s=[],i=[],a=[];n.Tu.isEmpty()||(n.Tu.forEach(((u,l)=>{a.push(n.pu(l,t,e).then((d=>{var f;if((d||e)&&n.isPrimaryClient){const g=d?!d.fromCache:(f=e==null?void 0:e.targetChanges.get(l.targetId))==null?void 0:f.current;n.sharedClientState.updateQueryState(l.targetId,g?"current":"not-current")}if(d){s.push(d);const g=Ta.Is(l.targetId,d);i.push(g)}})))})),await Promise.all(a),n.Pu.H_(s),await(async function(l,d){const f=F(l);try{await f.persistence.runTransaction("notifyLocalViewChanges","readwrite",(g=>v.forEach(d,(E=>v.forEach(E.Ts,(V=>f.persistence.referenceDelegate.addReference(g,E.targetId,V))).next((()=>v.forEach(E.Es,(V=>f.persistence.referenceDelegate.removeReference(g,E.targetId,V)))))))))}catch(g){if(!Se(g))throw g;P(wa,"Failed to update sequence numbers: "+g)}for(const g of d){const E=g.targetId;if(!g.fromCache){const V=f.vs.get(E),D=V.snapshotVersion,k=V.withLastLimboFreeSnapshotVersion(D);f.vs=f.vs.insert(E,k)}}})(n.localStore,i))}async function wy(r,t){const e=F(r);if(!e.currentUser.isEqual(t)){P(Qn,"User change. New user:",t.toKey());const n=await Pd(e.localStore,t);e.currentUser=t,(function(i,a){i.mu.forEach((u=>{u.forEach((l=>{l.reject(new C(S.CANCELLED,a))}))})),i.mu.clear()})(e,"'waitForPendingWrites' promise is rejected due to a user change."),e.sharedClientState.handleUserChange(t,n.removedBatchIds,n.addedBatchIds),await Pe(e,n.Ns)}}function vy(r,t){const e=F(r),n=e.Au.get(t);if(n&&n.hu)return $().add(n.key);{let s=$();const i=e.Eu.get(t);if(!i)return s;for(const a of i){const u=e.Tu.get(a);s=s.unionWith(u.view.nu)}return s}}async function Ay(r,t){const e=F(r),n=await ri(e.localStore,t.query,!0),s=t.view.cu(n);return e.isPrimaryClient&&Wo(e,t.targetId,s.au),s}async function by(r,t){const e=F(r);return xd(e.localStore,t).then((n=>Pe(e,n)))}async function Ry(r,t,e,n){const s=F(r),i=await(function(u,l){const d=F(u),f=F(d.mutationQueue);return d.persistence.runTransaction("Lookup mutation documents","readonly",(g=>f.Xn(g,l).next((E=>E?d.localDocuments.getDocuments(g,E):v.resolve(null)))))})(s.localStore,t);i!==null?(e==="pending"?await Kn(s.remoteStore):e==="acknowledged"||e==="rejected"?(ka(s,t,n||null),Na(s,t),(function(u,l){F(F(u).mutationQueue).nr(l)})(s.localStore,t)):O(6720,"Unknown batchState",{Su:e}),await Pe(s,i)):P(Qn,"Cannot apply mutation batch with id: "+t)}async function Sy(r,t){const e=F(r);if(Vi(e),Oa(e),t===!0&&e.gu!==!0){const n=e.sharedClientState.getAllActiveQueryTargets(),s=await gl(e,n.toArray());e.gu=!0,await Ho(e.remoteStore,!0);for(const i of s)Ri(e.remoteStore,i)}else if(t===!1&&e.gu!==!1){const n=[];let s=Promise.resolve();e.Eu.forEach(((i,a)=>{e.sharedClientState.isLocalQueryTarget(a)?n.push(a):s=s.then((()=>(qn(e,a),Ln(e.localStore,a,!0)))),Bn(e.remoteStore,a)})),await s,await gl(e,n),(function(a){const u=F(a);u.Au.forEach(((l,d)=>{Bn(u.remoteStore,d)})),u.Vu.zr(),u.Au=new Map,u.Ru=new nt(N.comparator)})(e),e.gu=!1,await Ho(e.remoteStore,!1)}}async function gl(r,t,e){const n=F(r),s=[],i=[];for(const a of t){let u;const l=n.Eu.get(a);if(l&&l.length!==0){u=await ni(n.localStore,Ot(l[0]));for(const d of l){const f=n.Tu.get(d),g=await Ay(n,f);g.snapshot&&i.push(g.snapshot)}}else{const d=await Dd(n.localStore,a);u=await ni(n.localStore,d),await xa(n,Xd(d),a,!1,u.resumeToken)}s.push(u)}return n.Pu.H_(i),s}function Xd(r){return Nh(r.path,r.collectionGroup,r.orderBy,r.filters,r.limit,"F",r.startAt,r.endAt)}function Vy(r){return(function(e){return F(F(e).persistence).hs()})(F(r).localStore)}async function Py(r,t,e,n){const s=F(r);if(s.gu)return void P(Qn,"Ignoring unexpected query state notification.");const i=s.Eu.get(t);if(i&&i.length>0)switch(e){case"current":case"not-current":{const a=await xd(s.localStore,Oh(i[0])),u=Zr.createSynthesizedRemoteEventForCurrentChange(t,e==="current",ht.EMPTY_BYTE_STRING);await Pe(s,a,u);break}case"rejected":await Ln(s.localStore,t,!0),qn(s,t,n);break;default:O(64155,e)}}async function Cy(r,t,e){const n=Vi(r);if(n.gu){for(const s of t){if(n.Eu.has(s)&&n.sharedClientState.isActiveQueryTarget(s)){P(Qn,"Adding an already active target "+s);continue}const i=await Dd(n.localStore,s),a=await ni(n.localStore,i);await xa(n,Xd(i),a.targetId,!1,a.resumeToken),Ri(n.remoteStore,a)}for(const s of e)n.Eu.has(s)&&await Ln(n.localStore,s,!1).then((()=>{Bn(n.remoteStore,s),qn(n,s)})).catch(Re)}}function Vi(r){const t=F(r);return t.remoteStore.remoteSyncer.applyRemoteEvent=Jd.bind(null,t),t.remoteStore.remoteSyncer.getRemoteKeysForTarget=vy.bind(null,t),t.remoteStore.remoteSyncer.rejectListen=yy.bind(null,t),t.Pu.H_=uy.bind(null,t.eventManager),t.Pu.yu=cy.bind(null,t.eventManager),t}function Oa(r){const t=F(r);return t.remoteStore.remoteSyncer.applySuccessfulWrite=Iy.bind(null,t),t.remoteStore.remoteSyncer.rejectFailedWrite=Ey.bind(null,t),t}class Gr{constructor(){this.kind="memory",this.synchronizeTabs=!1}async initialize(t){this.serializer=Ai(t.databaseInfo.databaseId),this.sharedClientState=this.Du(t),this.persistence=this.Cu(t),await this.persistence.start(),this.localStore=this.vu(t),this.gcScheduler=this.Fu(t,this.localStore),this.indexBackfillerScheduler=this.Mu(t,this.localStore)}Fu(t,e){return null}Mu(t,e){return null}vu(t){return Vd(this.persistence,new Sd,t.initialUser,this.serializer)}Cu(t){return new Ia(vi.Vi,this.serializer)}Du(t){return new Fd}async terminate(){var t,e;(t=this.gcScheduler)==null||t.stop(),(e=this.indexBackfillerScheduler)==null||e.stop(),this.sharedClientState.shutdown(),await this.persistence.shutdown()}}Gr.provider={build:()=>new Gr};class Dy extends Gr{constructor(t){super(),this.cacheSizeBytes=t}Fu(t,e){L(this.persistence.referenceDelegate instanceof ei,46915);const n=this.persistence.referenceDelegate.garbageCollector;return new Td(n,t.asyncQueue,e)}Cu(t){const e=this.cacheSizeBytes!==void 0?At.withCacheSize(this.cacheSizeBytes):At.DEFAULT;return new Ia((n=>ei.Vi(n,e)),this.serializer)}}class Zd extends Gr{constructor(t,e,n){super(),this.xu=t,this.cacheSizeBytes=e,this.forceOwnership=n,this.kind="persistent",this.synchronizeTabs=!1}async initialize(t){await super.initialize(t),await this.xu.initialize(this,t),await Oa(this.xu.syncEngine),await Kn(this.xu.remoteStore),await this.persistence.zi((()=>(this.gcScheduler&&!this.gcScheduler.started&&this.gcScheduler.start(),this.indexBackfillerScheduler&&!this.indexBackfillerScheduler.started&&this.indexBackfillerScheduler.start(),Promise.resolve())))}vu(t){return Vd(this.persistence,new Sd,t.initialUser,this.serializer)}Fu(t,e){const n=this.persistence.referenceDelegate.garbageCollector;return new Td(n,t.asyncQueue,e)}Mu(t,e){const n=new Bg(e,this.persistence);return new Lg(t.asyncQueue,n)}Cu(t){const e=Rd(t.databaseInfo.databaseId,t.databaseInfo.persistenceKey),n=this.cacheSizeBytes!==void 0?At.withCacheSize(this.cacheSizeBytes):At.DEFAULT;return new Ea(this.synchronizeTabs,e,t.clientId,n,t.asyncQueue,Ld(),Ls(),this.serializer,this.sharedClientState,!!this.forceOwnership)}Du(t){return new Fd}}class xy extends Zd{constructor(t,e){super(t,e,!1),this.xu=t,this.cacheSizeBytes=e,this.synchronizeTabs=!0}async initialize(t){await super.initialize(t);const e=this.xu.syncEngine;this.sharedClientState instanceof go&&(this.sharedClientState.syncEngine={bo:Ry.bind(null,e),Do:Py.bind(null,e),Co:Cy.bind(null,e),hs:Vy.bind(null,e),So:by.bind(null,e)},await this.sharedClientState.start()),await this.persistence.zi((async n=>{await Sy(this.xu.syncEngine,n),this.gcScheduler&&(n&&!this.gcScheduler.started?this.gcScheduler.start():n||this.gcScheduler.stop()),this.indexBackfillerScheduler&&(n&&!this.indexBackfillerScheduler.started?this.indexBackfillerScheduler.start():n||this.indexBackfillerScheduler.stop())}))}Du(t){const e=Ld();if(!go.v(e))throw new C(S.UNIMPLEMENTED,"IndexedDB persistence is only available on platforms that support LocalStorage.");const n=Rd(t.databaseInfo.databaseId,t.databaseInfo.persistenceKey);return new go(e,t.asyncQueue,n,t.clientId,t.initialUser)}}class Kr{async initialize(t,e){this.localStore||(this.localStore=t.localStore,this.sharedClientState=t.sharedClientState,this.datastore=this.createDatastore(e),this.remoteStore=this.createRemoteStore(e),this.eventManager=this.createEventManager(e),this.syncEngine=this.createSyncEngine(e,!t.synchronizeTabs),this.sharedClientState.onlineStateHandler=n=>ml(this.syncEngine,n,1),this.remoteStore.remoteSyncer.handleCredentialChange=wy.bind(null,this.syncEngine),await Ho(this.remoteStore,this.syncEngine.isPrimaryClient))}createEventManager(t){return(function(){return new ay})()}createDatastore(t){const e=Ai(t.databaseInfo.databaseId),n=j_(t.databaseInfo);return H_(t.authCredentials,t.appCheckCredentials,n,e)}createRemoteStore(t){return(function(n,s,i,a,u){return new W_(n,s,i,a,u)})(this.localStore,this.datastore,t.asyncQueue,(e=>ml(this.syncEngine,e,0)),(function(){return ul.v()?new ul:new L_})())}createSyncEngine(t,e){return(function(s,i,a,u,l,d,f){const g=new dy(s,i,a,u,l,d);return f&&(g.gu=!0),g})(this.localStore,this.remoteStore,this.eventManager,this.sharedClientState,t.initialUser,t.maxConcurrentLimboResolutions,e)}async terminate(){var t,e;await(async function(s){const i=F(s);P(nn,"RemoteStore shutting down."),i.Ia.add(5),await es(i),i.Aa.shutdown(),i.Va.set("Unknown")})(this.remoteStore),(t=this.datastore)==null||t.terminate(),(e=this.eventManager)==null||e.terminate()}}Kr.provider={build:()=>new Kr};/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *//**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Fa{constructor(t){this.observer=t,this.muted=!1}next(t){this.muted||this.observer.next&&this.Ou(this.observer.next,t)}error(t){this.muted||(this.observer.error?this.Ou(this.observer.error,t):lt("Uncaught Error in snapshot listener:",t.toString()))}Nu(){this.muted=!0}Ou(t,e){setTimeout((()=>{this.muted||t(e)}),0)}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const be="FirestoreClient";class Ny{constructor(t,e,n,s,i){this.authCredentials=t,this.appCheckCredentials=e,this.asyncQueue=n,this._databaseInfo=s,this.user=vt.UNAUTHENTICATED,this.clientId=Xo.newId(),this.authCredentialListener=()=>Promise.resolve(),this.appCheckCredentialListener=()=>Promise.resolve(),this._uninitializedComponentsProvider=i,this.authCredentials.start(n,(async a=>{P(be,"Received user=",a.uid),await this.authCredentialListener(a),this.user=a})),this.appCheckCredentials.start(n,(a=>(P(be,"Received new app check token=",a),this.appCheckCredentialListener(a,this.user))))}get configuration(){return{asyncQueue:this.asyncQueue,databaseInfo:this._databaseInfo,clientId:this.clientId,authCredentials:this.authCredentials,appCheckCredentials:this.appCheckCredentials,initialUser:this.user,maxConcurrentLimboResolutions:100}}setCredentialChangeListener(t){this.authCredentialListener=t}setAppCheckTokenChangeListener(t){this.appCheckCredentialListener=t}terminate(){this.asyncQueue.enterRestrictedMode();const t=new jt;return this.asyncQueue.enqueueAndForgetEvenWhileRestricted((async()=>{try{this._onlineComponents&&await this._onlineComponents.terminate(),this._offlineComponents&&await this._offlineComponents.terminate(),this.authCredentials.shutdown(),this.appCheckCredentials.shutdown(),t.resolve()}catch(e){const n=Si(e,"Failed to shutdown persistence");t.reject(n)}})),t.promise}}async function _o(r,t){r.asyncQueue.verifyOperationInProgress(),P(be,"Initializing OfflineComponentProvider");const e=r.configuration;await t.initialize(e);let n=e.initialUser;r.setCredentialChangeListener((async s=>{n.isEqual(s)||(await Pd(t.localStore,s),n=s)})),t.persistence.setDatabaseDeletedListener((()=>r.terminate())),r._offlineComponents=t}async function pl(r,t){r.asyncQueue.verifyOperationInProgress();const e=await tf(r);P(be,"Initializing OnlineComponentProvider"),await t.initialize(e,r.configuration),r.setCredentialChangeListener((n=>ll(t.remoteStore,n))),r.setAppCheckTokenChangeListener(((n,s)=>ll(t.remoteStore,s))),r._onlineComponents=t}async function tf(r){if(!r._offlineComponents)if(r._uninitializedComponentsProvider){P(be,"Using user provided OfflineComponentProvider");try{await _o(r,r._uninitializedComponentsProvider._offline)}catch(t){const e=t;if(!(function(s){return s.name==="FirebaseError"?s.code===S.FAILED_PRECONDITION||s.code===S.UNIMPLEMENTED:!(typeof DOMException<"u"&&s instanceof DOMException)||s.code===22||s.code===20||s.code===11})(e))throw e;vn("Error using user provided cache. Falling back to memory cache: "+e),await _o(r,new Gr)}}else P(be,"Using default OfflineComponentProvider"),await _o(r,new Dy(void 0));return r._offlineComponents}async function ef(r){return r._onlineComponents||(r._uninitializedComponentsProvider?(P(be,"Using user provided OnlineComponentProvider"),await pl(r,r._uninitializedComponentsProvider._online)):(P(be,"Using default OnlineComponentProvider"),await pl(r,new Kr))),r._onlineComponents}function ky(r){return tf(r).then((t=>t.localStore))}function My(r){return ef(r).then((t=>t.syncEngine))}async function ai(r){const t=await ef(r),e=t.eventManager;return e.onListen=fy.bind(null,t.syncEngine),e.onUnlisten=gy.bind(null,t.syncEngine),e.onFirstRemoteStoreListen=my.bind(null,t.syncEngine),e.onLastRemoteStoreUnlisten=py.bind(null,t.syncEngine),e}function Oy(r,t,e,n){const s=new Fa(n),i=new Da(t,s,e);return r.asyncQueue.enqueueAndForget((async()=>Va(await ai(r),i))),()=>{s.Nu(),r.asyncQueue.enqueueAndForget((async()=>Pa(await ai(r),i)))}}function nf(r,t,e={}){const n=new jt;return r.asyncQueue.enqueueAndForget((async()=>(function(i,a,u,l,d){const f=new Fa({next:E=>{f.Nu(),a.enqueueAndForget((()=>Pa(i,g)));const V=E.docs.has(u);!V&&E.fromCache?d.reject(new C(S.UNAVAILABLE,"Failed to get document because the client is offline.")):V&&E.fromCache&&l&&l.source==="server"?d.reject(new C(S.UNAVAILABLE,'Failed to get document from server. (However, this document does exist in the local cache. Run again without setting source to "server" to retrieve the cached document.)')):d.resolve(E)},error:E=>d.reject(E)}),g=new Da(Jr(u.path),f,{includeMetadataChanges:!0,qa:!0});return Va(i,g)})(await ai(r),r.asyncQueue,t,e,n))),n.promise}function Fy(r,t){const e=new jt;return r.asyncQueue.enqueueAndForget((async()=>(async function(s,i,a){try{const u=await ri(s,i,!0),l=new Qd(i,u.ks),d=l.ru(u.documents),f=l.applyChanges(d,!1);a.resolve(f.snapshot)}catch(u){const l=Si(u,`Failed to execute query '${i} against cache`);a.reject(l)}})(await ky(r),t,e))),e.promise}function rf(r,t,e={}){const n=new jt;return r.asyncQueue.enqueueAndForget((async()=>(function(i,a,u,l,d){const f=new Fa({next:E=>{f.Nu(),a.enqueueAndForget((()=>Pa(i,g))),E.fromCache&&l.source==="server"?d.reject(new C(S.UNAVAILABLE,'Failed to get documents from server. (However, these documents may exist in the local cache. Run again without setting source to "server" to retrieve the cached documents.)')):d.resolve(E)},error:E=>d.reject(E)}),g=new Da(u,f,{includeMetadataChanges:!0,qa:!0});return Va(i,g)})(await ai(r),r.asyncQueue,t,e,n))),n.promise}function Ly(r,t){const e=new jt;return r.asyncQueue.enqueueAndForget((async()=>_y(await My(r),t,e))),e.promise}/**
 * @license
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function sf(r){const t={};return r.timeoutSeconds!==void 0&&(t.timeoutSeconds=r.timeoutSeconds),t}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const By="ComponentProvider",_l=new Map;function Uy(r,t,e,n,s){return new fp(r,t,e,s.host,s.ssl,s.experimentalForceLongPolling,s.experimentalAutoDetectLongPolling,sf(s.experimentalLongPollingOptions),s.useFetchStreams,s.isUsingEmulator,n)}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const qy="firestore.googleapis.com",yl=!0;class Il{constructor(t){if(t.host===void 0){if(t.ssl!==void 0)throw new C(S.INVALID_ARGUMENT,"Can't provide ssl option if host option is not set");this.host=qy,this.ssl=yl}else this.host=t.host,this.ssl=t.ssl??yl;if(this.isUsingEmulator=t.emulatorOptions!==void 0,this.credentials=t.credentials,this.ignoreUndefinedProperties=!!t.ignoreUndefinedProperties,this.localCache=t.localCache,t.cacheSizeBytes===void 0)this.cacheSizeBytes=pd;else{if(t.cacheSizeBytes!==-1&&t.cacheSizeBytes<Ed)throw new C(S.INVALID_ARGUMENT,"cacheSizeBytes must be at least 1048576");this.cacheSizeBytes=t.cacheSizeBytes}Mg("experimentalForceLongPolling",t.experimentalForceLongPolling,"experimentalAutoDetectLongPolling",t.experimentalAutoDetectLongPolling),this.experimentalForceLongPolling=!!t.experimentalForceLongPolling,this.experimentalForceLongPolling?this.experimentalAutoDetectLongPolling=!1:t.experimentalAutoDetectLongPolling===void 0?this.experimentalAutoDetectLongPolling=!0:this.experimentalAutoDetectLongPolling=!!t.experimentalAutoDetectLongPolling,this.experimentalLongPollingOptions=sf(t.experimentalLongPollingOptions??{}),(function(n){if(n.timeoutSeconds!==void 0){if(isNaN(n.timeoutSeconds))throw new C(S.INVALID_ARGUMENT,`invalid long polling timeout: ${n.timeoutSeconds} (must not be NaN)`);if(n.timeoutSeconds<5)throw new C(S.INVALID_ARGUMENT,`invalid long polling timeout: ${n.timeoutSeconds} (minimum allowed value is 5)`);if(n.timeoutSeconds>30)throw new C(S.INVALID_ARGUMENT,`invalid long polling timeout: ${n.timeoutSeconds} (maximum allowed value is 30)`)}})(this.experimentalLongPollingOptions),this.useFetchStreams=!!t.useFetchStreams}isEqual(t){return this.host===t.host&&this.ssl===t.ssl&&this.credentials===t.credentials&&this.cacheSizeBytes===t.cacheSizeBytes&&this.experimentalForceLongPolling===t.experimentalForceLongPolling&&this.experimentalAutoDetectLongPolling===t.experimentalAutoDetectLongPolling&&(function(n,s){return n.timeoutSeconds===s.timeoutSeconds})(this.experimentalLongPollingOptions,t.experimentalLongPollingOptions)&&this.ignoreUndefinedProperties===t.ignoreUndefinedProperties&&this.useFetchStreams===t.useFetchStreams}}class La{constructor(t,e,n,s){this._authCredentials=t,this._appCheckCredentials=e,this._databaseId=n,this._app=s,this.type="firestore-lite",this._persistenceKey="(lite)",this._settings=new Il({}),this._settingsFrozen=!1,this._emulatorOptions={},this._terminateTask="notTerminated"}get app(){if(!this._app)throw new C(S.FAILED_PRECONDITION,"Firestore was not initialized using the Firebase SDK. 'app' is not available");return this._app}get _initialized(){return this._settingsFrozen}get _terminated(){return this._terminateTask!=="notTerminated"}_setSettings(t){if(this._settingsFrozen)throw new C(S.FAILED_PRECONDITION,"Firestore has already been started and its settings can no longer be changed. You can only modify settings before calling any other methods on a Firestore object.");this._settings=new Il(t),this._emulatorOptions=t.emulatorOptions||{},t.credentials!==void 0&&(this._authCredentials=(function(n){if(!n)return new Rg;switch(n.type){case"firstParty":return new Pg(n.sessionIndex||"0",n.iamToken||null,n.authTokenFactory||null);case"provider":return n.client;default:throw new C(S.INVALID_ARGUMENT,"makeAuthCredentialsProvider failed due to invalid credential type")}})(t.credentials))}_getSettings(){return this._settings}_getEmulatorOptions(){return this._emulatorOptions}_freezeSettings(){return this._settingsFrozen=!0,this._settings}_delete(){return this._terminateTask==="notTerminated"&&(this._terminateTask=this._terminate()),this._terminateTask}async _restart(){this._terminateTask==="notTerminated"?await this._terminate():this._terminateTask="notTerminated"}toJSON(){return{app:this._app,databaseId:this._databaseId,settings:this._settings}}_terminate(){return(function(e){const n=_l.get(e);n&&(P(By,"Removing Datastore"),_l.delete(e),n.terminate())})(this),Promise.resolve()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Xt{constructor(t,e,n){this.converter=e,this._query=n,this.type="query",this.firestore=t}withConverter(t){return new Xt(this.firestore,t,this._query)}}class at{constructor(t,e,n){this.converter=e,this._key=n,this.type="document",this.firestore=t}get _path(){return this._key.path}get id(){return this._key.path.lastSegment()}get path(){return this._key.path.canonicalString()}get parent(){return new Te(this.firestore,this.converter,this._key.path.popLast())}withConverter(t){return new at(this.firestore,t,this._key)}toJSON(){return{type:at._jsonSchemaVersion,referencePath:this._key.toString()}}static fromJSON(t,e,n){if(Hr(e,at._jsonSchema))return new at(t,n||null,new N(Y.fromString(e.referencePath)))}}at._jsonSchemaVersion="firestore/documentReference/1.0",at._jsonSchema={type:ft("string",at._jsonSchemaVersion),referencePath:ft("string")};class Te extends Xt{constructor(t,e,n){super(t,e,Jr(n)),this._path=n,this.type="collection"}get id(){return this._query.path.lastSegment()}get path(){return this._query.path.canonicalString()}get parent(){const t=this._path.popLast();return t.isEmpty()?null:new at(this.firestore,null,new N(t))}withConverter(t){return new Te(this.firestore,t,this._path)}}function gI(r,t,...e){if(r=Ut(r),Xl("collection","path",t),r instanceof La){const n=Y.fromString(t,...e);return cc(n),new Te(r,null,n)}{if(!(r instanceof at||r instanceof Te))throw new C(S.INVALID_ARGUMENT,"Expected first argument to collection() to be a CollectionReference, a DocumentReference or FirebaseFirestore");const n=r._path.child(Y.fromString(t,...e));return cc(n),new Te(r.firestore,null,n)}}function jy(r,t,...e){if(r=Ut(r),arguments.length===1&&(t=Xo.newId()),Xl("doc","path",t),r instanceof La){const n=Y.fromString(t,...e);return uc(n),new at(r,null,new N(n))}{if(!(r instanceof at||r instanceof Te))throw new C(S.INVALID_ARGUMENT,"Expected first argument to doc() to be a CollectionReference, a DocumentReference or FirebaseFirestore");const n=r._path.child(Y.fromString(t,...e));return uc(n),new at(r.firestore,r instanceof Te?r.converter:null,new N(n))}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const El="AsyncQueue";class Tl{constructor(t=Promise.resolve()){this.Yu=[],this.ec=!1,this.tc=[],this.nc=null,this.rc=!1,this.sc=!1,this.oc=[],this.M_=new Bd(this,"async_queue_retry"),this._c=()=>{const n=Ls();n&&P(El,"Visibility state changed to "+n.visibilityState),this.M_.w_()},this.ac=t;const e=Ls();e&&typeof e.addEventListener=="function"&&e.addEventListener("visibilitychange",this._c)}get isShuttingDown(){return this.ec}enqueueAndForget(t){this.enqueue(t)}enqueueAndForgetEvenWhileRestricted(t){this.uc(),this.cc(t)}enterRestrictedMode(t){if(!this.ec){this.ec=!0,this.sc=t||!1;const e=Ls();e&&typeof e.removeEventListener=="function"&&e.removeEventListener("visibilitychange",this._c)}}enqueue(t){if(this.uc(),this.ec)return new Promise((()=>{}));const e=new jt;return this.cc((()=>this.ec&&this.sc?Promise.resolve():(t().then(e.resolve,e.reject),e.promise))).then((()=>e.promise))}enqueueRetryable(t){this.enqueueAndForget((()=>(this.Yu.push(t),this.lc())))}async lc(){if(this.Yu.length!==0){try{await this.Yu[0](),this.Yu.shift(),this.M_.reset()}catch(t){if(!Se(t))throw t;P(El,"Operation failed with retryable error: "+t)}this.Yu.length>0&&this.M_.p_((()=>this.lc()))}}cc(t){const e=this.ac.then((()=>(this.rc=!0,t().catch((n=>{throw this.nc=n,this.rc=!1,lt("INTERNAL UNHANDLED ERROR: ",wl(n)),n})).then((n=>(this.rc=!1,n))))));return this.ac=e,e}enqueueAfterDelay(t,e,n){this.uc(),this.oc.indexOf(t)>-1&&(e=0);const s=Sa.createAndSchedule(this,t,e,n,(i=>this.hc(i)));return this.tc.push(s),s}uc(){this.nc&&O(47125,{Pc:wl(this.nc)})}verifyOperationInProgress(){}async Tc(){let t;do t=this.ac,await t;while(t!==this.ac)}Ec(t){for(const e of this.tc)if(e.timerId===t)return!0;return!1}Ic(t){return this.Tc().then((()=>{this.tc.sort(((e,n)=>e.targetTimeMs-n.targetTimeMs));for(const e of this.tc)if(e.skipDelay(),t!=="all"&&e.timerId===t)break;return this.Tc()}))}Rc(t){this.oc.push(t)}hc(t){const e=this.tc.indexOf(t);this.tc.splice(e,1)}}function wl(r){let t=r.message||"";return r.stack&&(t=r.stack.includes(r.message)?r.stack:r.message+`
`+r.stack),t}class Lt extends La{constructor(t,e,n,s){super(t,e,n,s),this.type="firestore",this._queue=new Tl,this._persistenceKey=(s==null?void 0:s.name)||"[DEFAULT]"}async _terminate(){if(this._firestoreClient){const t=this._firestoreClient.terminate();this._queue=new Tl(t),this._firestoreClient=void 0,await t}}}function pI(r,t,e){e||(e=Hs);const n=ug(r,"firestore");if(n.isInitialized(e)){const s=n.getImmediate({identifier:e}),i=n.getOptions(e);if(Us(i,t))return s;throw new C(S.FAILED_PRECONDITION,"initializeFirestore() has already been called with different options. To avoid this error, call initializeFirestore() with the same options as when it was originally called, or call getFirestore() to return the already initialized instance.")}if(t.cacheSizeBytes!==void 0&&t.localCache!==void 0)throw new C(S.INVALID_ARGUMENT,"cache and cacheSizeBytes cannot be specified at the same time as cacheSizeBytes willbe deprecated. Instead, specify the cache size in the cache object");if(t.cacheSizeBytes!==void 0&&t.cacheSizeBytes!==-1&&t.cacheSizeBytes<Ed)throw new C(S.INVALID_ARGUMENT,"cacheSizeBytes must be at least 1048576");return t.host&&Ll(t.host)&&hm(t.host),n.initialize({options:t,instanceIdentifier:e})}function Ce(r){if(r._terminated)throw new C(S.FAILED_PRECONDITION,"The client has already been terminated.");return r._firestoreClient||zy(r),r._firestoreClient}function zy(r){var n,s,i,a;const t=r._freezeSettings(),e=Uy(r._databaseId,((n=r._app)==null?void 0:n.options.appId)||"",r._persistenceKey,(s=r._app)==null?void 0:s.options.apiKey,t);r._componentsProvider||(i=t.localCache)!=null&&i._offlineComponentProvider&&((a=t.localCache)!=null&&a._onlineComponentProvider)&&(r._componentsProvider={_offline:t.localCache._offlineComponentProvider,_online:t.localCache._onlineComponentProvider}),r._firestoreClient=new Ny(r._authCredentials,r._appCheckCredentials,r._queue,e,r._componentsProvider&&(function(l){const d=l==null?void 0:l._online.build();return{_offline:l==null?void 0:l._offline.build(d),_online:d}})(r._componentsProvider))}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Bt{constructor(t){this._byteString=t}static fromBase64String(t){try{return new Bt(ht.fromBase64String(t))}catch(e){throw new C(S.INVALID_ARGUMENT,"Failed to construct data from Base64 string: "+e)}}static fromUint8Array(t){return new Bt(ht.fromUint8Array(t))}toBase64(){return this._byteString.toBase64()}toUint8Array(){return this._byteString.toUint8Array()}toString(){return"Bytes(base64: "+this.toBase64()+")"}isEqual(t){return this._byteString.isEqual(t._byteString)}toJSON(){return{type:Bt._jsonSchemaVersion,bytes:this.toBase64()}}static fromJSON(t){if(Hr(t,Bt._jsonSchema))return Bt.fromBase64String(t.bytes)}}Bt._jsonSchemaVersion="firestore/bytes/1.0",Bt._jsonSchema={type:ft("string",Bt._jsonSchemaVersion),bytes:ft("string")};/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Pi{constructor(...t){for(let e=0;e<t.length;++e)if(t[e].length===0)throw new C(S.INVALID_ARGUMENT,"Invalid field name at argument $(i + 1). Field names must not be empty.");this._internalPath=new ot(t)}isEqual(t){return this._internalPath.isEqual(t._internalPath)}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Ci{constructor(t){this._methodName=t}}/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Jt{constructor(t,e){if(!isFinite(t)||t<-90||t>90)throw new C(S.INVALID_ARGUMENT,"Latitude must be a number between -90 and 90, but was: "+t);if(!isFinite(e)||e<-180||e>180)throw new C(S.INVALID_ARGUMENT,"Longitude must be a number between -180 and 180, but was: "+e);this._lat=t,this._long=e}get latitude(){return this._lat}get longitude(){return this._long}isEqual(t){return this._lat===t._lat&&this._long===t._long}_compareTo(t){return U(this._lat,t._lat)||U(this._long,t._long)}toJSON(){return{latitude:this._lat,longitude:this._long,type:Jt._jsonSchemaVersion}}static fromJSON(t){if(Hr(t,Jt._jsonSchema))return new Jt(t.latitude,t.longitude)}}Jt._jsonSchemaVersion="firestore/geoPoint/1.0",Jt._jsonSchema={type:ft("string",Jt._jsonSchemaVersion),latitude:ft("number"),longitude:ft("number")};/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class zt{constructor(t){this._values=(t||[]).map((e=>e))}toArray(){return this._values.map((t=>t))}isEqual(t){return(function(n,s){if(n.length!==s.length)return!1;for(let i=0;i<n.length;++i)if(n[i]!==s[i])return!1;return!0})(this._values,t._values)}toJSON(){return{type:zt._jsonSchemaVersion,vectorValues:this._values}}static fromJSON(t){if(Hr(t,zt._jsonSchema)){if(Array.isArray(t.vectorValues)&&t.vectorValues.every((e=>typeof e=="number")))return new zt(t.vectorValues);throw new C(S.INVALID_ARGUMENT,"Expected 'vectorValues' field to be a number array")}}}zt._jsonSchemaVersion="firestore/vectorValue/1.0",zt._jsonSchema={type:ft("string",zt._jsonSchemaVersion),vectorValues:ft("object")};/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const $y=/^__.*__$/;class Gy{constructor(t,e,n){this.data=t,this.fieldMask=e,this.fieldTransforms=n}toMutation(t,e){return this.fieldMask!==null?new ie(t,this.data,this.fieldMask,e,this.fieldTransforms):new Gn(t,this.data,e,this.fieldTransforms)}}class of{constructor(t,e,n){this.data=t,this.fieldMask=e,this.fieldTransforms=n}toMutation(t,e){return new ie(t,this.data,this.fieldMask,e,this.fieldTransforms)}}function af(r){switch(r){case 0:case 2:case 1:return!0;case 3:case 4:return!1;default:throw O(40011,{dataSource:r})}}class Ba{constructor(t,e,n,s,i,a){this.settings=t,this.databaseId=e,this.serializer=n,this.ignoreUndefinedProperties=s,i===void 0&&this.Ac(),this.fieldTransforms=i||[],this.fieldMask=a||[]}get path(){return this.settings.path}get dataSource(){return this.settings.dataSource}i(t){return new Ba({...this.settings,...t},this.databaseId,this.serializer,this.ignoreUndefinedProperties,this.fieldTransforms,this.fieldMask)}dc(t){var s;const e=(s=this.path)==null?void 0:s.child(t),n=this.i({path:e,arrayElement:!1});return n.mc(t),n}fc(t){var s;const e=(s=this.path)==null?void 0:s.child(t),n=this.i({path:e,arrayElement:!1});return n.Ac(),n}gc(t){return this.i({path:void 0,arrayElement:!0})}yc(t){return ui(t,this.settings.methodName,this.settings.hasConverter||!1,this.path,this.settings.targetDoc)}contains(t){return this.fieldMask.find((e=>t.isPrefixOf(e)))!==void 0||this.fieldTransforms.find((e=>t.isPrefixOf(e.field)))!==void 0}Ac(){if(this.path)for(let t=0;t<this.path.length;t++)this.mc(this.path.get(t))}mc(t){if(t.length===0)throw this.yc("Document fields must not be empty");if(af(this.dataSource)&&$y.test(t))throw this.yc('Document fields cannot begin and end with "__"')}}class Ky{constructor(t,e,n){this.databaseId=t,this.ignoreUndefinedProperties=e,this.serializer=n||Ai(t)}A(t,e,n,s=!1){return new Ba({dataSource:t,methodName:e,targetDoc:n,path:ot.emptyPath(),arrayElement:!1,hasConverter:s},this.databaseId,this.serializer,this.ignoreUndefinedProperties)}}function ns(r){const t=r._freezeSettings(),e=Ai(r._databaseId);return new Ky(r._databaseId,!!t.ignoreUndefinedProperties,e)}function Ua(r,t,e,n,s,i={}){const a=r.A(i.merge||i.mergeFields?2:0,t,e,s);ja("Data must be an object, but it was:",a,n);const u=lf(n,a);let l,d;if(i.merge)l=new xt(a.fieldMask),d=a.fieldTransforms;else if(i.mergeFields){const f=[];for(const g of i.mergeFields){const E=rn(t,g,e);if(!a.contains(E))throw new C(S.INVALID_ARGUMENT,`Field '${E}' is specified in your field mask but missing from your input data.`);ff(f,E)||f.push(E)}l=new xt(f),d=a.fieldTransforms.filter((g=>l.covers(g.field)))}else l=null,d=a.fieldTransforms;return new Gy(new bt(u),l,d)}class Di extends Ci{_toFieldTransform(t){if(t.dataSource!==2)throw t.dataSource===1?t.yc(`${this._methodName}() can only appear at the top level of your update data`):t.yc(`${this._methodName}() cannot be used with set() unless you pass {merge:true}`);return t.fieldMask.push(t.path),null}isEqual(t){return t instanceof Di}}class qa extends Ci{_toFieldTransform(t){return new Kh(t.path,new kn)}isEqual(t){return t instanceof qa}}function uf(r,t,e,n){const s=r.A(1,t,e);ja("Data must be an object, but it was:",s,n);const i=[],a=bt.empty();Ve(n,((l,d)=>{const f=df(t,l,e);d=Ut(d);const g=s.fc(f);if(d instanceof Di)i.push(f);else{const E=rs(d,g);E!=null&&(i.push(f),a.set(f,E))}}));const u=new xt(i);return new of(a,u,s.fieldTransforms)}function cf(r,t,e,n,s,i){const a=r.A(1,t,e),u=[rn(t,n,e)],l=[s];if(i.length%2!=0)throw new C(S.INVALID_ARGUMENT,`Function ${t}() needs to be called with an even number of arguments that alternate between field names and values.`);for(let E=0;E<i.length;E+=2)u.push(rn(t,i[E])),l.push(i[E+1]);const d=[],f=bt.empty();for(let E=u.length-1;E>=0;--E)if(!ff(d,u[E])){const V=u[E];let D=l[E];D=Ut(D);const k=a.fc(V);if(D instanceof Di)d.push(V);else{const M=rs(D,k);M!=null&&(d.push(V),f.set(V,M))}}const g=new xt(d);return new of(f,g,a.fieldTransforms)}function Hy(r,t,e,n=!1){return rs(e,r.A(n?4:3,t))}function rs(r,t){if(hf(r=Ut(r)))return ja("Unsupported field value:",t,r),lf(r,t);if(r instanceof Ci)return(function(n,s){if(!af(s.dataSource))throw s.yc(`${n._methodName}() can only be used with update() and set()`);if(!s.path)throw s.yc(`${n._methodName}() is not currently supported inside arrays`);const i=n._toFieldTransform(s);i&&s.fieldTransforms.push(i)})(r,t),null;if(r===void 0&&t.ignoreUndefinedProperties)return null;if(t.path&&t.fieldMask.push(t.path),r instanceof Array){if(t.settings.arrayElement&&t.dataSource!==4)throw t.yc("Nested arrays are not supported");return(function(n,s){const i=[];let a=0;for(const u of n){let l=rs(u,s.gc(a));l==null&&(l={nullValue:"NULL_VALUE"}),i.push(l),a++}return{arrayValue:{values:i}}})(r,t)}return(function(n,s){if((n=Ut(n))===null)return{nullValue:"NULL_VALUE"};if(typeof n=="number")return Np(s.serializer,n);if(typeof n=="boolean")return{booleanValue:n};if(typeof n=="string")return{stringValue:n};if(n instanceof Date){const i=X.fromDate(n);return{timestampValue:Fn(s.serializer,i)}}if(n instanceof X){const i=new X(n.seconds,1e3*Math.floor(n.nanoseconds/1e3));return{timestampValue:Fn(s.serializer,i)}}if(n instanceof Jt)return{geoPointValue:{latitude:n.latitude,longitude:n.longitude}};if(n instanceof Bt)return{bytesValue:Zh(s.serializer,n._byteString)};if(n instanceof at){const i=s.databaseId,a=n.firestore._databaseId;if(!a.isEqual(i))throw s.yc(`Document reference is for database ${a.projectId}/${a.database} but should be for database ${i.projectId}/${i.database}`);return{referenceValue:ga(n.firestore._databaseId||s.databaseId,n._key.path)}}if(n instanceof zt)return(function(a,u){const l=a instanceof zt?a.toArray():a;return{mapValue:{fields:{[oa]:{stringValue:aa},[Cn]:{arrayValue:{values:l.map((f=>{if(typeof f!="number")throw u.yc("VectorValues must only contain numeric values.");return la(u.serializer,f)}))}}}}}})(n,s);if(ld(n))return n._toProto(s.serializer);throw s.yc(`Unsupported field value: ${li(n)}`)})(r,t)}function lf(r,t){const e={};return ph(r)?t.path&&t.path.length>0&&t.fieldMask.push(t.path):Ve(r,((n,s)=>{const i=rs(s,t.dc(n));i!=null&&(e[n]=i)})),{mapValue:{fields:e}}}function hf(r){return!(typeof r!="object"||r===null||r instanceof Array||r instanceof Date||r instanceof X||r instanceof Jt||r instanceof Bt||r instanceof at||r instanceof Ci||r instanceof zt||ld(r))}function ja(r,t,e){if(!hf(e)||!Zl(e)){const n=li(e);throw n==="an object"?t.yc(r+" a custom object"):t.yc(r+" "+n)}}function rn(r,t,e){if((t=Ut(t))instanceof Pi)return t._internalPath;if(typeof t=="string")return df(r,t);throw ui("Field path arguments must be of type string or ",r,!1,void 0,e)}const Qy=new RegExp("[~\\*/\\[\\]]");function df(r,t,e){if(t.search(Qy)>=0)throw ui(`Invalid field path (${t}). Paths must not contain '~', '*', '/', '[', or ']'`,r,!1,void 0,e);try{return new Pi(...t.split("."))._internalPath}catch{throw ui(`Invalid field path (${t}). Paths must not be empty, begin with '.', end with '.', or contain '..'`,r,!1,void 0,e)}}function ui(r,t,e,n,s){const i=n&&!n.isEmpty(),a=s!==void 0;let u=`Function ${t}() called with invalid data`;e&&(u+=" (via `toFirestore()`)"),u+=". ";let l="";return(i||a)&&(l+=" (found",i&&(l+=` in field ${n}`),a&&(l+=` in document ${s}`),l+=")"),new C(S.INVALID_ARGUMENT,u+r+l)}function ff(r,t){return r.some((e=>e.isEqual(t)))}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class Wy{convertValue(t,e="none"){switch(we(t)){case 0:return null;case 1:return t.booleanValue;case 2:return it(t.integerValue||t.doubleValue);case 3:return this.convertTimestamp(t.timestampValue);case 4:return this.convertServerTimestamp(t,e);case 5:return t.stringValue;case 6:return this.convertBytes(re(t.bytesValue));case 7:return this.convertReference(t.referenceValue);case 8:return this.convertGeoPoint(t.geoPointValue);case 9:return this.convertArray(t.arrayValue,e);case 11:return this.convertObject(t.mapValue,e);case 10:return this.convertVectorValue(t.mapValue);default:throw O(62114,{value:t})}}convertObject(t,e){return this.convertObjectMap(t.fields,e)}convertObjectMap(t,e="none"){const n={};return Ve(t,((s,i)=>{n[s]=this.convertValue(i,e)})),n}convertVectorValue(t){var n,s,i;const e=(i=(s=(n=t.fields)==null?void 0:n[Cn].arrayValue)==null?void 0:s.values)==null?void 0:i.map((a=>it(a.doubleValue)));return new zt(e)}convertGeoPoint(t){return new Jt(it(t.latitude),it(t.longitude))}convertArray(t,e){return(t.values||[]).map((n=>this.convertValue(n,e)))}convertServerTimestamp(t,e){switch(e){case"previous":const n=pi(t);return n==null?null:this.convertValue(n,e);case"estimate":return this.convertTimestamp(Br(t));default:return null}}convertTimestamp(t){const e=ne(t);return new X(e.seconds,e.nanos)}convertDocumentKey(t,e){const n=Y.fromString(t);L(cd(n),9688,{name:t});const s=new Ye(n.get(1),n.get(3)),i=new N(n.popFirst(5));return s.isEqual(e)||lt(`Document ${i} contains a document reference within a different database (${s.projectId}/${s.database}) which is not supported. It will be treated as a reference in the current database (${e.projectId}/${e.database}) instead.`),i}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ss extends Wy{constructor(t){super(),this.firestore=t}convertBytes(t){return new Bt(t)}convertReference(t){const e=this.convertDocumentKey(t,this.firestore._databaseId);return new at(this.firestore,null,e)}}function _I(){return new qa("serverTimestamp")}const vl="@firebase/firestore",Al="4.13.0";/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function bl(r){return(function(e,n){if(typeof e!="object"||e===null)return!1;const s=e;for(const i of n)if(i in s&&typeof s[i]=="function")return!0;return!1})(r,["next","error","complete"])}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class mf{constructor(t,e,n,s,i){this._firestore=t,this._userDataWriter=e,this._key=n,this._document=s,this._converter=i}get id(){return this._key.path.lastSegment()}get ref(){return new at(this._firestore,this._converter,this._key)}exists(){return this._document!==null}data(){if(this._document){if(this._converter){const t=new Jy(this._firestore,this._userDataWriter,this._key,this._document,null);return this._converter.fromFirestore(t)}return this._userDataWriter.convertValue(this._document.data.value)}}_fieldsProto(){var t;return((t=this._document)==null?void 0:t.data.clone().value.mapValue.fields)??void 0}get(t){if(this._document){const e=this._document.data.field(rn("DocumentSnapshot.get",t));if(e!==null)return this._userDataWriter.convertValue(e)}}}class Jy extends mf{data(){return super.data()}}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function gf(r){if(r.limitType==="L"&&r.explicitOrderBy.length===0)throw new C(S.UNIMPLEMENTED,"limitToLast() queries require specifying at least one orderBy() clause")}class za{}class pf extends za{}function yI(r,t,...e){let n=[];t instanceof za&&n.push(t),n=n.concat(e),(function(i){const a=i.filter((l=>l instanceof $a)).length,u=i.filter((l=>l instanceof xi)).length;if(a>1||a>0&&u>0)throw new C(S.INVALID_ARGUMENT,"InvalidQuery. When using composite filters, you cannot use more than one filter at the top level. Consider nesting the multiple filters within an `and(...)` statement. For example: change `query(query, where(...), or(...))` to `query(query, and(where(...), or(...)))`.")})(n);for(const s of n)r=s._apply(r);return r}class xi extends pf{constructor(t,e,n){super(),this._field=t,this._op=e,this._value=n,this.type="where"}static _create(t,e,n){return new xi(t,e,n)}_apply(t){const e=this._parse(t);return _f(t._query,e),new Xt(t.firestore,t.converter,Oo(t._query,e))}_parse(t){const e=ns(t.firestore);return(function(i,a,u,l,d,f,g){let E;if(d.isKeyField()){if(f==="array-contains"||f==="array-contains-any")throw new C(S.INVALID_ARGUMENT,`Invalid Query. You can't perform '${f}' queries on documentId().`);if(f==="in"||f==="not-in"){Sl(g,f);const D=[];for(const k of g)D.push(Rl(l,i,k));E={arrayValue:{values:D}}}else E=Rl(l,i,g)}else f!=="in"&&f!=="not-in"&&f!=="array-contains-any"||Sl(g,f),E=Hy(u,a,g,f==="in"||f==="not-in");return G.create(d,f,E)})(t._query,"where",e,t.firestore._databaseId,this._field,this._op,this._value)}}function II(r,t,e){const n=t,s=rn("where",r);return xi._create(s,n,e)}class $a extends za{constructor(t,e){super(),this.type=t,this._queryConstraints=e}static _create(t,e){return new $a(t,e)}_parse(t){const e=this._queryConstraints.map((n=>n._parse(t))).filter((n=>n.getFilters().length>0));return e.length===1?e[0]:Z.create(e,this._getOperator())}_apply(t){const e=this._parse(t);return e.getFilters().length===0?t:((function(s,i){let a=s;const u=i.getFlattenedFilters();for(const l of u)_f(a,l),a=Oo(a,l)})(t._query,e),new Xt(t.firestore,t.converter,Oo(t._query,e)))}_getQueryConstraints(){return this._queryConstraints}_getOperator(){return this.type==="and"?"and":"or"}}class Ga extends pf{constructor(t,e){super(),this._field=t,this._direction=e,this.type="orderBy"}static _create(t,e){return new Ga(t,e)}_apply(t){const e=(function(s,i,a){if(s.startAt!==null)throw new C(S.INVALID_ARGUMENT,"Invalid query. You must not call startAt() or startAfter() before calling orderBy().");if(s.endAt!==null)throw new C(S.INVALID_ARGUMENT,"Invalid query. You must not call endAt() or endBefore() before calling orderBy().");return new zr(i,a)})(t._query,this._field,this._direction);return new Xt(t.firestore,t.converter,Sp(t._query,e))}}function EI(r,t="asc"){const e=t,n=rn("orderBy",r);return Ga._create(n,e)}function Rl(r,t,e){if(typeof(e=Ut(e))=="string"){if(e==="")throw new C(S.INVALID_ARGUMENT,"Invalid query. When querying with documentId(), you must provide a valid document ID, but it was an empty string.");if(!kh(t)&&e.indexOf("/")!==-1)throw new C(S.INVALID_ARGUMENT,`Invalid query. When querying a collection by documentId(), you must provide a plain document ID, but '${e}' contains a '/' character.`);const n=t.path.child(Y.fromString(e));if(!N.isDocumentKey(n))throw new C(S.INVALID_ARGUMENT,`Invalid query. When querying a collection group by documentId(), the value provided must result in a valid document path, but '${n}' is not because it has an odd number of segments (${n.length}).`);return qr(r,new N(n))}if(e instanceof at)return qr(r,e._key);throw new C(S.INVALID_ARGUMENT,`Invalid query. When querying with documentId(), you must provide a valid string or a DocumentReference, but it was: ${li(e)}.`)}function Sl(r,t){if(!Array.isArray(r)||r.length===0)throw new C(S.INVALID_ARGUMENT,`Invalid Query. A non-empty array is required for '${t.toString()}' filters.`)}function _f(r,t){const e=(function(s,i){for(const a of s)for(const u of a.getFlattenedFilters())if(i.indexOf(u.op)>=0)return u.op;return null})(r.filters,(function(s){switch(s){case"!=":return["!=","not-in"];case"array-contains-any":case"in":return["not-in"];case"not-in":return["array-contains-any","in","not-in","!="];default:return[]}})(t.op));if(e!==null)throw e===t.op?new C(S.INVALID_ARGUMENT,`Invalid query. You cannot use more than one '${t.op.toString()}' filter.`):new C(S.INVALID_ARGUMENT,`Invalid query. You cannot use '${t.op.toString()}' filters with '${e.toString()}' filters.`)}function Ka(r,t,e){let n;return n=r?e&&(e.merge||e.mergeFields)?r.toFirestore(t,e):r.toFirestore(t):t,n}class Yy{constructor(t){let e;this.kind="persistent",t!=null&&t.tabManager?(t.tabManager._initialize(t),e=t.tabManager):(e=tI(void 0),e._initialize(t)),this._onlineComponentProvider=e._onlineComponentProvider,this._offlineComponentProvider=e._offlineComponentProvider}toJSON(){return{kind:this.kind}}}function TI(r){return new Yy(r)}class Xy{constructor(t){this.forceOwnership=t,this.kind="persistentSingleTab"}toJSON(){return{kind:this.kind}}_initialize(t){this._onlineComponentProvider=Kr.provider,this._offlineComponentProvider={build:e=>new Zd(e,t==null?void 0:t.cacheSizeBytes,this.forceOwnership)}}}class Zy{constructor(){this.kind="PersistentMultipleTab"}toJSON(){return{kind:this.kind}}_initialize(t){this._onlineComponentProvider=Kr.provider,this._offlineComponentProvider={build:e=>new xy(e,t==null?void 0:t.cacheSizeBytes)}}}function tI(r){return new Xy(r==null?void 0:r.forceOwnership)}function wI(){return new Zy}class Tr{constructor(t,e){this.hasPendingWrites=t,this.fromCache=e}isEqual(t){return this.hasPendingWrites===t.hasPendingWrites&&this.fromCache===t.fromCache}}class We extends mf{constructor(t,e,n,s,i,a){super(t,e,n,s,a),this._firestore=t,this._firestoreImpl=t,this.metadata=i}exists(){return super.exists()}data(t={}){if(this._document){if(this._converter){const e=new Bs(this._firestore,this._userDataWriter,this._key,this._document,this.metadata,null);return this._converter.fromFirestore(e,t)}return this._userDataWriter.convertValue(this._document.data.value,t.serverTimestamps)}}get(t,e={}){if(this._document){const n=this._document.data.field(rn("DocumentSnapshot.get",t));if(n!==null)return this._userDataWriter.convertValue(n,e.serverTimestamps)}}toJSON(){if(this.metadata.hasPendingWrites)throw new C(S.FAILED_PRECONDITION,"DocumentSnapshot.toJSON() attempted to serialize a document with pending writes. Await waitForPendingWrites() before invoking toJSON().");const t=this._document,e={};return e.type=We._jsonSchemaVersion,e.bundle="",e.bundleSource="DocumentSnapshot",e.bundleName=this._key.toString(),!t||!t.isValidDocument()||!t.isFoundDocument()?e:(this._userDataWriter.convertObjectMap(t.data.value.mapValue.fields,"previous"),e.bundle=(this._firestore,this.ref.path,"NOT SUPPORTED"),e)}}We._jsonSchemaVersion="firestore/documentSnapshot/1.0",We._jsonSchema={type:ft("string",We._jsonSchemaVersion),bundleSource:ft("string","DocumentSnapshot"),bundleName:ft("string"),bundle:ft("string")};class Bs extends We{data(t={}){return super.data(t)}}class te{constructor(t,e,n,s){this._firestore=t,this._userDataWriter=e,this._snapshot=s,this.metadata=new Tr(s.hasPendingWrites,s.fromCache),this.query=n}get docs(){const t=[];return this.forEach((e=>t.push(e))),t}get size(){return this._snapshot.docs.size}get empty(){return this.size===0}forEach(t,e){this._snapshot.docs.forEach((n=>{t.call(e,new Bs(this._firestore,this._userDataWriter,n.key,n,new Tr(this._snapshot.mutatedKeys.has(n.key),this._snapshot.fromCache),this.query.converter))}))}docChanges(t={}){const e=!!t.includeMetadataChanges;if(e&&this._snapshot.excludesMetadataChanges)throw new C(S.INVALID_ARGUMENT,"To include metadata changes with your document changes, you must also pass { includeMetadataChanges:true } to onSnapshot().");return this._cachedChanges&&this._cachedChangesIncludeMetadataChanges===e||(this._cachedChanges=(function(s,i){if(s._snapshot.oldDocs.isEmpty()){let a=0;return s._snapshot.docChanges.map((u=>{const l=new Bs(s._firestore,s._userDataWriter,u.doc.key,u.doc,new Tr(s._snapshot.mutatedKeys.has(u.doc.key),s._snapshot.fromCache),s.query.converter);return u.doc,{type:"added",doc:l,oldIndex:-1,newIndex:a++}}))}{let a=s._snapshot.oldDocs;return s._snapshot.docChanges.filter((u=>i||u.type!==3)).map((u=>{const l=new Bs(s._firestore,s._userDataWriter,u.doc.key,u.doc,new Tr(s._snapshot.mutatedKeys.has(u.doc.key),s._snapshot.fromCache),s.query.converter);let d=-1,f=-1;return u.type!==0&&(d=a.indexOf(u.doc.key),a=a.delete(u.doc.key)),u.type!==1&&(a=a.add(u.doc),f=a.indexOf(u.doc.key)),{type:eI(u.type),doc:l,oldIndex:d,newIndex:f}}))}})(this,e),this._cachedChangesIncludeMetadataChanges=e),this._cachedChanges}toJSON(){if(this.metadata.hasPendingWrites)throw new C(S.FAILED_PRECONDITION,"QuerySnapshot.toJSON() attempted to serialize a document with pending writes. Await waitForPendingWrites() before invoking toJSON().");const t={};t.type=te._jsonSchemaVersion,t.bundleSource="QuerySnapshot",t.bundleName=Xo.newId(),this._firestore._databaseId.database,this._firestore._databaseId.projectId;const e=[],n=[],s=[];return this.docs.forEach((i=>{i._document!==null&&(e.push(i._document),n.push(this._userDataWriter.convertObjectMap(i._document.data.value.mapValue.fields,"previous")),s.push(i.ref.path))})),t.bundle=(this._firestore,this.query._query,t.bundleName,"NOT SUPPORTED"),t}}function eI(r){switch(r){case 0:return"added";case 2:case 3:return"modified";case 1:return"removed";default:return O(61501,{type:r})}}/**
 * @license
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */te._jsonSchemaVersion="firestore/querySnapshot/1.0",te._jsonSchema={type:ft("string",te._jsonSchemaVersion),bundleSource:ft("string","QuerySnapshot"),bundleName:ft("string"),bundle:ft("string")};/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class nI{constructor(t,e){this._firestore=t,this._commitHandler=e,this._mutations=[],this._committed=!1,this._dataReader=ns(t)}set(t,e,n){this._verifyNotCommitted();const s=yo(t,this._firestore),i=Ka(s.converter,e,n),a=Ua(this._dataReader,"WriteBatch.set",s._key,i,s.converter!==null,n);return this._mutations.push(a.toMutation(s._key,pt.none())),this}update(t,e,n,...s){this._verifyNotCommitted();const i=yo(t,this._firestore);let a;return a=typeof(e=Ut(e))=="string"||e instanceof Pi?cf(this._dataReader,"WriteBatch.update",i._key,e,n,s):uf(this._dataReader,"WriteBatch.update",i._key,e),this._mutations.push(a.toMutation(i._key,pt.exists(!0))),this}delete(t){this._verifyNotCommitted();const e=yo(t,this._firestore);return this._mutations=this._mutations.concat(new Xr(e._key,pt.none())),this}commit(){return this._verifyNotCommitted(),this._committed=!0,this._mutations.length>0?this._commitHandler(this._mutations):Promise.resolve()}_verifyNotCommitted(){if(this._committed)throw new C(S.FAILED_PRECONDITION,"A write batch can no longer be used after commit() has been called.")}}function yo(r,t){if((r=Ut(r)).firestore!==t)throw new C(S.INVALID_ARGUMENT,"Provided document reference is from a different Firestore instance.");return r}/**
 * @license
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function vI(r){r=mt(r,at);const t=mt(r.firestore,Lt),e=Ce(t);return nf(e,r._key).then((n=>Ha(t,r,n)))}function AI(r){r=mt(r,at);const t=mt(r.firestore,Lt),e=Ce(t);return nf(e,r._key,{source:"server"}).then((n=>Ha(t,r,n)))}function bI(r){r=mt(r,Xt);const t=mt(r.firestore,Lt),e=Ce(t),n=new ss(t);return gf(r._query),rf(e,r._query).then((s=>new te(t,n,r,s)))}function RI(r){r=mt(r,Xt);const t=mt(r.firestore,Lt),e=Ce(t),n=new ss(t);return Fy(e,r._query).then((s=>new te(t,n,r,s)))}function SI(r){r=mt(r,Xt);const t=mt(r.firestore,Lt),e=Ce(t),n=new ss(t);return rf(e,r._query,{source:"server"}).then((s=>new te(t,n,r,s)))}function VI(r,t,e){r=mt(r,at);const n=mt(r.firestore,Lt),s=Ka(r.converter,t,e),i=ns(n);return is(n,[Ua(i,"setDoc",r._key,s,r.converter!==null,e).toMutation(r._key,pt.none())])}function PI(r,t,e,...n){r=mt(r,at);const s=mt(r.firestore,Lt),i=ns(s);let a;return a=typeof(t=Ut(t))=="string"||t instanceof Pi?cf(i,"updateDoc",r._key,t,e,n):uf(i,"updateDoc",r._key,t),is(s,[a.toMutation(r._key,pt.exists(!0))])}function CI(r){return is(mt(r.firestore,Lt),[new Xr(r._key,pt.none())])}function DI(r,t){const e=mt(r.firestore,Lt),n=jy(r),s=Ka(r.converter,t),i=ns(r.firestore);return is(e,[Ua(i,"addDoc",n._key,s,r.converter!==null,{}).toMutation(n._key,pt.exists(!1))]).then((()=>n))}function xI(r,...t){var d,f,g;r=Ut(r);let e={includeMetadataChanges:!1,source:"default"},n=0;typeof t[n]!="object"||bl(t[n])||(e=t[n++]);const s={includeMetadataChanges:e.includeMetadataChanges,source:e.source};if(bl(t[n])){const E=t[n];t[n]=(d=E.next)==null?void 0:d.bind(E),t[n+1]=(f=E.error)==null?void 0:f.bind(E),t[n+2]=(g=E.complete)==null?void 0:g.bind(E)}let i,a,u;if(r instanceof at)a=mt(r.firestore,Lt),u=Jr(r._key.path),i={next:E=>{t[n]&&t[n](Ha(a,r,E))},error:t[n+1],complete:t[n+2]};else{const E=mt(r,Xt);a=mt(E.firestore,Lt),u=E._query;const V=new ss(a);i={next:D=>{t[n]&&t[n](new te(a,V,E,D))},error:t[n+1],complete:t[n+2]},gf(r._query)}const l=Ce(a);return Oy(l,u,s,i)}function is(r,t){const e=Ce(r);return Ly(e,t)}function Ha(r,t,e){const n=e.docs.get(t._key),s=new ss(r);return new We(r,s,t._key,n,new Tr(e.hasPendingWrites,e.fromCache),t.converter)}function NI(r){return r=mt(r,Lt),Ce(r),new nI(r,(t=>is(r,t)))}(function(t,e=!0){Ag(dg),js(new xr("firestore",((n,{instanceIdentifier:s,options:i})=>{const a=n.getProvider("app").getImmediate(),u=new Lt(new Sg(n.getProvider("auth-internal")),new Cg(a,n.getProvider("app-check-internal")),mp(a,s),a);return i={useFetchStreams:e,...i},u._setSettings(i),u}),"PUBLIC").setMultipleInstances(!0)),wr(vl,Al,t),wr(vl,Al,"esm2020")})();export{vI as A,VI as B,xr as C,_I as D,Fl as E,jn as F,xI as G,yI as H,EI as I,II as J,gI as K,Bl as L,NI as M,PI as N,AI as O,bI as P,CI as Q,DI as R,dg as S,SI as T,RI as U,js as _,uI as a,aI as b,cg as c,Ut as d,dI as e,Q as f,sI as g,wn as h,iI as i,tm as j,Ll as k,ug as l,rI as m,fI as n,Us as o,hm as p,hI as q,wr as r,cI as s,lI as t,oI as u,fg as v,pI as w,TI as x,wI as y,jy as z};
