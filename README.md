# GoogleCloudStorage
Implement Google Cloud Storage Rest XML Api
See https://cloud.google.com/storage/docs/migrating

## Installation 
This API can be installed as standalone or as a ColdBox Module.  Either approach requires a simple CommandBox command:

```
box install GoogleClouldStorage
```

Then follow either the standalone or module instructions below.

### Standalone

This API will be installed into a directory called `GoogleCloudStorage` and then the SDK can be instantiated via ` new s3sdk.AmazonS3()` with the following constructor arguments:

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

See https://cloud.google.com/storage/docs/migrating
