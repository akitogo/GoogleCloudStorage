# GoogleCloudStorage
Implements Google Cloud Storage Rest XML Api for Coldbox Coldfusion
See https://cloud.google.com/storage/docs/migrating

## Installation 
This API can be installed as standalone or as a ColdBox Module.  Either approach requires a simple CommandBox command:

```
box install GoogleCloudStorage
```

Then follow either the standalone or module instructions below.

### Standalone

This API will be installed into a directory called `GoogleCloudStorage` and then the API can be instantiated via ` new GoogleCloudStoreage.models.GoogleStorage()` with the following constructor arguments:

```
<cfargument name="accessKey" 			required="true">
<cfargument name="secretKey" 			required="true">
<cfargument name="encryption_charset" 	required="false" default="utf-8">
<cfargument name="ssl" 					required="false" default="false">
```

### ColdBox Module

This package also is a ColdBox module as well.  The module can be configured by creating an `GoogleStorageSettings` configuration structure in your application configuration file: `config/Coldbox.cfc` with the following settings:

```
GoogleStorageSettings = {
	// Your Google access key
	accessKey = "",
	// Your Google secret key
	secretKey = "",
	// The default encryption character set
	encryption_charset = "utf-8",
	// SSL mode or not on cfhttp calls.
	ssl = false
};
```

Then you can leverage the API CFC via the injection DSL: `GoogleStorage@GoogleCloudStorage`

## Usage
```
component{
	property name="ggl" inject="GoogleStorage@GoogleCloudStorage";
	
	function index(event,rc,prc){
		
		// get all buckets
		var allBuckets=ggl.listBuckets();
		
		// store a file in a buckets
		var uploadedFile=ggl.putObjectFile('akitogo','C:\temp\myfile.jpg');
		writeDump(allBuckets);
		writeDump(uploadedFile);
		abort;
	}
}
```

## Written by
www.akitogo.com

## Disclaimer
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
