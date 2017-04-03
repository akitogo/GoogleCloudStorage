/*

Google Cloud Storge Api
Check: https://cloud.google.com/storage/docs/migrating

Written by Akitogo Team
http://www.akitogo.com

This component is a fork of 
https://github.com/coldbox-modules/s3sdk


Originally written by Joe Danziger (joe@ajaxcf.com) with much help from
dorioo on the Amazon S3 Forums.  See the readme for more
details on usage and methods.
Thanks to Steve Hicks for the bucket ACL updates.
Thanks to Carlos Gallupa for the EU storage location updates.
Thanks to Joel Greutman for the fix on the getObject link.
Thanks to Jerad Sloan for the Cache Control headers.

Coldbox Version by Luis Majano .

You will have to create some settings in your ColdBox configuration file:

s3_accessKey : The Amazon access key
s3_secretKey : The Amazon secret key
s3_encryption_charset : encryptyion charset (Optional, defaults to utf-8)
s3_ssl : Whether to use ssl on all cals or not (Optional, defaults to false)

*/
component hint="Google Cloud Storage REST Wrapper" accessors="true" Singleton{
	
	/* DI */
	property name="log" inject="logbox:logger:{this}";

	/* Properties */
	property name="accessKey";
	property name="secretKey";
	property name="encryption_charset";
	property name="ssl";
	property name="URLEndPoint";
	

	// STATIC Constants
	this.ACL_PRIVATE 			= "private";
	this.ACL_PUBLIC_READ 		= "public-read";
	this.ACL_PUBLIC_READ_WRITE 	= "public-read-write";
	this.ACL_AUTH_READ 			= "authenticated-read";

/*	public GoogleStorage function init() {
		return this;
	}
*/
	public GoogleStorage function init(
		string accessKey
		,string secretKey
		,string encryption_charset="utf-8"
		,boolean ssl=false
	){

		for( var thiskey in arguments ){
			variables[ thisKey ] = arguments[ thisKey ];
		}

		if( arguments.ssl ){
			variables.URLEndPoint = "https://storage.googleapis.com"; 
		} else{ 
			variables.URLEndPoint = "http://storage.googleapis.com"; 
		}

		return this;
	}

	/* setAuth */
    public void function setAuth(
    	string accessKey
    	,string secretKey
    ){
		variables.accessKey = arguments.accessKey;
		variables.secretKey = arguments.secretKey;
    }

	/* setSSL 
	 * Set SSL flag and alter the internal URL End point pointer
	 */
    public void function setSSL(
    	boolean useSSL=true
    ) {
		if( arguments.useSSL ){
			variables.URLEndPoint = "https://storage.googleapis.com"; 
		} else{ 
			variables.URLEndPoint = "http://storage.googleapis.com"; 
		}
    }

	/*---------------------------------------- PUBLIC ---------------------------------------*/

	/* Create Signature 
	 * Create request signature according to AWS standards
	*/
	public any function createSignature(
		string stringToSign
	){
			var fixedData = replace( arguments.stringToSign, "\n", "#chr(10)#", "all" );

			return toBase64( HMAC_SHA1( variables.secretKey, fixedData ) );
	}

	/* Get All Buckets 
	 * List all available buckets.
 	 */
	public array function listBuckets(){
		// Invoke call
		var results = S3Request();

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}
		// Parse out buckets
		var foundBuckets 	= [];
		var bucketsXML 		= xmlSearch( results.response, "//*[local-name()='Bucket']" );
		for( var x=1; x lte arrayLen( bucketsXML ); x++ ){
			var thisBucket = {
				name = trim( bucketsXML[ x ].name.xmlText ),
				creationDate = trim( bucketsXML[ x ].creationDate.xmlText )
			};
			arrayAppend( foundBuckets, thisBucket );
		}
		return foundBuckets;
	}


	/* getBucketLocation */
	public string function getBucketLocation(
		string bucketName
	){
		// Invoke call
		var results = S3Request( resource=arguments.bucketname & "?location" );

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		// Parse out EU buckets
		if( len( results.response.LocationConstraint.XMLText ) ){
			return results.response.LocationConstraint.XMLText;
		}

		return "US";
	}

	/* getBucketVersionStatus */
	public string function getBucketVersionStatus(
		string bucketName
	){
		// Invoke call
		var results = S3Request(resource=arguments.bucketname & "?versioning");

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		var status = xmlSearch( results.response, "//*[local-name()='VersioningConfiguration']//*[local-name()='Status']/*[1]" );

		// Parse out Version Configuration
		if( arrayLen( status ) gt 0 ){
			return status[ 1 ].xmlText;
		}

		return "";
	}

	/*setBucketVersion
	 * bucketName.hint	The name of the bucket to create
	 * version.hint		the version status enabled/disabled.
	*/
	public boolean function setBucketVersionStatus(
		string bucketName
		,boolean version=true
	){
		
		var constraintXML 	= "";
		var headers 		= {};
		var amzHeaders 		= {};

		// Headers init
		headers[ "content-type" ] = "text/plain";

		if( arguments.version eq true ){
			headers[ "?versioning" ] = "";
			constraintXML = '<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>Enabled</Status></VersioningConfiguration>';
		}

		// Invoke call
		var results = S3Request(
			method 		= "PUT",
			resource	= arguments.bucketName,
			body 		= constraintXML,
			headers 	= headers,
			amzHeaders	= amzHeaders
		);

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		if( results.responseheader.status_code eq "200"){
			return true;
		}

		return false;
	}

	/* Get getAcessControlPolicy 
	 * Get's a bucket or object's ACL policy
	 * bucketName.hint	The bucket name to list
	 * bucketName.hint	The object URI to get the policy
	 */
	public array function getAcessControlPolicy(
		string bucketName
		,string uri=""
	){
		var resource = arguments.bucketName;

		// incoming URI
		if( len( arguments.uri ) ){ 
			resource = resource & "\" & arguments.uri; 
		}

		// Invoke call
		var results = S3Request( resource=resource & "?acl" );

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		// Parse Grants
		var grantsXML 	= xmlSearch( results.response, "//*[local-name()='Grant']" );
		var foundGrants = [];
		for( var x=1; x lte arrayLen( grantsXML ); x++ ){
			var thisGrant = {
				type 		= grantsXML[ x ].grantee.XMLAttributes[ "xsi:type" ],
				uri 		= "",
				displayName = "",
				permission	= grantsXML[ x ].permission.XMLText
			};
			if( thisGrant.type eq "Group" ){
				thisGrant.uri = grantsXML[ x ].grantee.uri.xmlText;
			}
			else{
				thisGrant.uri = grantsXML[ x ].grantee.displayName.xmlText;
			}
			arrayAppend( foundGrants, thisGrant );
		}

		return foundGrants;
	}

	/* Get Bucket 
	 * Lists information about the objects of a bucket
	 * bucketName.hint	The bucket name to list
	 * prefix.hint	Limits the response to keys which begin with the indicated prefix
	 * marker.hint	Indicates where in the bucket to begin listing.
	 * maxKeys.hint	The maximum number of keys you'd like to see in the response body
	 * delimiter.hint	The delimiter to use in the keys
	 * 
	*/
	public array function getBucket(
		string bucketName
		,string prefix=""
		,string marker=""
		,string maxKeys=""
		,string delimiter="" 
	){
		var headers 		= [];
		var parameters 		= {};

		//HTTP parameters
		if( len(arguments.prefix) ){
			parameters[ "prefix" ] = arguments.prefix;
		}
		if( len(arguments.marker) ){
			parameters[ "marker" ] = arguments.marker;
		}
		if( isNumeric(arguments.maxKeys) ){
			parameters[ "max-keys" ] = arguments.maxKeys;
		}
		if( len(arguments.delimiter) ){
			parameters[ "delimiter" ] = arguments.delimiter;
		}

		// Invoke call
		var results = S3Request(
			resource 	= arguments.bucketName,
			parameters 	= parameters
		);
		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		// Parse results
		var contentsXML 	= xmlSearch( results.response, "//*[local-name()='Contents']" );
		var foundContents 	= [];
		for( var x=1; x lte arrayLen( contentsXML ); x++ ){
			var thisContent = {
				key				= trim( contentsXML[ x ].key.xmlText ),
				lastModified	= trim( contentsXML[ x ].lastModified.xmlText ),
				size			= trim( contentsXML[ x ].Size.xmlText ),
				eTag 			= trim( contentsXML[ x ].etag.xmlText ),
				isDirectory 	= ( findNoCase( "_$folder$", contentsXML[ x ].key.xmlText ) ? true : false )
			};
			arrayAppend( foundContents, thisContent );
		}

		// parse directories
		var foldersXML 	= xmlSearch( results.response, "//*[local-name()='CommonPrefixes']" );
		for( var x=1; x lte arrayLen( foldersXML ); x++ ){
			var thisContent = {
				key				= reReplaceNoCase( trim( foldersXML[ x ].prefix.xmlText ), "\/$", "" ),
				lastModified	= '',
				size			= '',
				eTag 			= '',
				isDirectory 	= true
			};
			arrayAppend( foundContents, thisContent );
		}

		return foundContents;
	}

	/* Put Bucket 
	 * Creates a bucket
	 * bucketName.hint	The bucket name to list
	 * acl.hint			The ACL permissions to apply. Use the this scope constants for ease of use.
	 * location.hint		The location of the storage, defaults to USA or EU
	 * 
	*/	
	public boolean function putBucket(
		string bucketName
		,string acl=this.ACL_PUBLIC_READ
		,string location='USA'
	) {
		var constraintXML 	= "";
		var headers 		= {};
		var amzHeaders 		= {};

		// Man cf8 really did implicit structures NASTY!!
		amzHeaders[ "x-amz-acl" ] = arguments.acl;

		// storage location?
		if( arguments.location eq "EU" ){
			constraintXML = "<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>";
		}

		// Headers
		headers[ "content-type" ] = "text/xml";

		// Invoke call
		var results = S3Request(
			method 		= "PUT",
			resource 	= arguments.bucketName,
			body 		= constraintXML,
			headers 	= headers,
			amzHeaders 	= amzHeaders
		);

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		if( results.responseheader.status_code eq "200"){
			return true;
		}

		return false;
	}

	/* Delete a Bucket */
	public boolean function deleteBucket(
		string bucketName
	){
		// Invoke call
		var results = S3Request(
			method 	 = "DELETE",
			resource = arguments.bucketName
		);

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		if( results.responseheader.status_code eq "204"){ return true; }

		return false;
	}

	/* Put an object from a local file 
	 * Puts an object from a local file into a bucket and returns the etag
	 * @bucketName.hint The bucket to store in
	 * @filepath.hint the absolute file path to read in binary and upload
	 * @uri.hint The destination uri key to use when saving the object, if not used, the name of the file will be used.
	 * @contentType.hint The file content type, defaults to: binary/octet-stream
	 * @HTTPTimeout.hint The HTTP timeout to use
	 * @cacheControl.hint The caching header to send. Defaults to no caching. Example: public,max-age=864000  (10days). For more info look here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 * @expires.hint Sets the expiration header of the object in days.
	 * @acl.hint The default Amazon security access policy
	 * @metaHeaders.hint Add additonal metadata headers to the file by passing a struct of name-value pairs
	*/
	public string function putObjectFile(
		string bucketName
		,string filepath	
		,string uri=""
		,string contentType="binary/octet-stream"
		,numeric HTTPTimeout=300
		,string cacheControl="no-store, no-cache, must-revalidate"
		,string expires=""
		,string acl=this.ACL_PUBLIC_READ
		,struct metaHeaders={}
	){
		// Read the binary file
		arguments.data = fileReadBinary( arguments.filepath );

		// Default filename
		if( NOT len( arguments.uri ) ){
			arguments.uri = getFileFromPath( arguments.filePath );
		}

		//Encode the filepath
		arguments.uri = urlEncodedFormat( arguments.uri );

		// Send to putObject
		return putObject( argumentCollection=arguments );
	}

	/* Put a folder 
	 * @bucketName.hint The bucket to store in
	 * @filepath.hint the absolute file path to read in binary and upload
	 * @uri.hint The destination uri key to use when saving the object, if not used, the name of the file will be used.
	 * @contentType.hint The file content type, defaults to: binary/octet-stream
	 * @HTTPTimeout.hint The HTTP timeout to use
	 * @cacheControl.hint The caching header to send. Defaults to no caching. Example: public,max-age=864000  (10days). For more info look here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 * @expires.hint Sets the expiration header of the object in days.
	 * @acl.hint The default Amazon security access policy
	 * @metaHeaders.hint Add additonal metadata headers to the file by passing a struct of name-value pairs
	*/
	public string function putObjectFolder(
		string bucketName
		,string uri=""
		,string contentType="binary/octet-stream"
		,numeric HTTPTimeout=300
		,string cacheControl="no-store, no-cache, must-revalidate"
		,string expires=""
		,string acl=this.ACL_PUBLIC_READ
		,struct metaHeaders={}
		
	){
		// Read the binary file
		arguments.data = "";

		// Send to putObject
		return putObject( argumentCollection=arguments );
	}

	/* createMetaHeaders 
	* Create a structure of amazon enabled metadata headers
	* @metaHeaders.hint Add additonal metadata headers to the file by passing a struct of name-value pairs
	*/
    public struct function createMetaHeaders(
    	struct metaHeaders={}
    ){
    	
			var md = {};
			for( var key in arguments.metaHeaders ){
				md[ "x-amz-meta-" & key ] = arguments.metaHeaders[ key ];
			}
			return md;
    }

	/* Put An Object
	 * Puts an object into a bucket and returns the etag
	 * @bucketName.hint The bucket to store in
	 * @uri.hint The destination uri key to use when saving the object, if not used, the name of the file will be used.
	 * @data.hint The content to save as data, this can be binary,string or anything you like.
	 * @contentType.hint The file content type, defaults to: binary/octet-stream
	 * @contentDisposition.hint The content-disposition header to use when downloading file
	 * @HTTPTimeout.hint The HTTP timeout to use
	 * @cacheControl.hint The caching header to send. Defaults to no caching. Example: public,max-age=864000  (10days). For more info look here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 * @expires.hint Sets the expiration header of the object in days.
	 * @acl.hint The default Amazon security access policy
	 * @metaHeaders.hint Add additonal metadata headers to the file by passing a struct of name-value pairs

	 */
	public string function putObject(
		string bucketName
		,string uri
		,any data
		,string contentDisposition
		,string contentType="text/plain"
		,numeric HTTPTimeout=300
		,string cacheControl="no-store, no-cache, must-revalidate"
		,string expires=""
		,string acl=this.ACL_PUBLIC_READ
		,struct metaHeaders={}
		
	){
		var headers 	= {};
		var amzHeaders 	= createMetaHeaders( arguments.metaHeaders );

		// Add security to amzHeaders
		amzHeaders[ "x-amz-acl" ] = arguments.acl;

		// Add Global Put Headers
		headers[ "content-type" ]  = arguments.contentType;
		headers[ "cache-control" ] = arguments.cacheControl;

		// Content Disposition
		if( len( arguments.contentDisposition ) ){
			headers[ "content-disposition" ] = arguments.contentDisposition;
		}

		// Expiration header if set
		if( isNumeric( arguments.expires ) ){
			headers[ "expires" ] = "#DateFormat( now() + arguments.expires, 'ddd, dd mmm yyyy' )# #TimeFormat( now(), 'H:MM:SS' )# GMT";
		}

		// Invoke call
		results = S3Request(
			method 			= "PUT",
			resource 		= arguments.bucketName & "/" & arguments.uri,
			body 			= arguments.data,
			timeout 		= arguments.HTTPTimeout,
			headers 		= headers,
			amzHeaders 		= amzHeaders
		);

		// error
		if( results.error ){
			throw( message="Error making Google REST call", detail=results.message );
		}

		// Get results
		if( results.responseHeader.status_code eq "200" ){
			return results.responseHeader.etag;
		}

		return "";
	}

	/* Get Object Info
	 * Get an object's metadata information
	 * @bucketName.hint The bucket the object resides in
	 * @uri.hint The object URI to retrieve info from
	 */
	public struct function getObjectInfo(
		string bucketName
		,string uri		
	){
			var metadata = {};

			// Invoke call
			var results = S3Request( method="HEAD", resource=arguments.bucketName & "/" & arguments.uri );

			// error
			if( results.error ){
				throw( message="Error making Google REST call", detail=results.message );
			}

			// Get metadata
			for( var key in results.responseHeader ){
				metadata[ key ] = results.responseHeader[ key ];
			}

			return metadata;
	}

	/* Get Secure Link To an Object
	 * Returns a query string authenticated URL to an object in S3.
	 * @bucketName.hint The bucket the object resides in
	 * @uri.hint The uri to the object to create a link for
	 * @minutesValid.hint The minutes the link is valid for. Defaults to 60 minutes
	 * @virtualHostStyle.hint Whether to use virtual bucket style or path style. Defaults to virtual
	 * @useSSL.hint Use SSL on http call
	
	*/
	public string function getAuthenticatedURL(
		string bucketName
		,string uri	
		,numeric minutesValid=60
		,boolean virtualHostStyle=false
		,boolean useSSL=false
	){
			var epochTime 	= DateDiff( "s", DateConvert( "utc2Local", "January 1 1970 00:00" ), now()) + ( arguments.minutesValid * 60 );
			var HTTPPrefix 	= "http://";

			arguments.uri = urlEncodedFormat( arguments.uri );
			arguments.uri = replacenocase( arguments.uri,"%2E",".","all" );
			arguments.uri = replacenocase( arguments.uri,"%2D","-","all" );
			arguments.uri = replacenocase( arguments.uri,"%5F","_","all" );

			var stringToSign = "GET\n\n\n#epochTime#\n/#arguments.bucketName#/#arguments.uri#";

			// Sign the request
			var signature 	= createSignature( stringToSign );
			signature 		= urlEncodedFormat( signature );
			//signature = replace(signature,"%3D","%","all");

			//securedLink = "#arguments.uri#?AWSAccessKeyId=#variables.accessKey#&Expires=#epochTime#&Signature=#replace(signature,"%3D","%","all")#";
			var securedLink = "#arguments.uri#?AWSAccessKeyId=#variables.accessKey#&Expires=#epochTime#&Signature=#signature#";

			// Log it
			log.debug( "String to sign: #stringToSign# . Signature: #signature#" );

			// SSL?
			if( arguments.useSSL ){ 
				HTTPPrefix = "https://"; 
			}

			// VH style Link
			if( arguments.virtualHostSTyle ){
				return "#HTTPPrefix##arguments.bucketName#.storage.googleapis.com/#securedLink#";
			}

			// Path Style Link
			return "#HTTPPrefix#storage.googleapis.com/#arguments.bucketName#/#securedLink#";
	}

		/* Delete Object 
		 * @bucketName.hint The bucket name
		 * @uri.hint The file object uri to remove
		*/
		public boolean function deleteObject(
			string bucketName
			,string uri	
		){
			arguments.uri = urlEncodedFormat( urlDecode( arguments.uri ) );
			arguments.uri = replacenocase( arguments.uri, "%2E", ".", "all" );
			arguments.uri = replacenocase( arguments.uri, "%2D", "-", "all" );
			arguments.uri = replacenocase( arguments.uri, "%5F", "_", "all" );
			
			// Invoke call
			var results = S3Request( method="DELETE", resource=arguments.bucketName & "/" & arguments.uri );

			// error
			if( results.error ){
				throw( message="Error making Google REST call", detail=results.message );
			}

			if( results.responseheader.status_code eq "204"){ return true; }

			return false;
	}

	/* Copy Object 
	 * Copies an object. False if the same object or error copying object.
	 * @fromBucket.hint The source bucket
	 * @fromURI.hint The source uri
	 * @toBucket.hint The destination bucket
	 * @toURI.hint The destination uri
	 * @acl.hint The default Amazon security access policy
	 * @uri.metaHeaders Replace metadata headers to the file by passing a struct of name-value pairs
	 */	
	public boolean function copyObject(
		string fromBucket
		,string fromURI
		,string toBucket
		,string toURI
		,string acl=this.ACL_PRIVATE
		,metaHeaders={}
	) {
			var headers 	= {};
			var amzHeaders 	= createMetaHeaders( arguments.metaHeaders );

			// Copy metaHeaders or replace?
			if( not structIsEmpty( arguments.metaHeaders ) ){
				amzHeaders[ "x-amz-metadata-directive" ] = "REPLACE";
			}

			// amz copying headers
			amzHeaders[ "x-amz-copy-source" ] 	= "/#arguments.fromBucket#/#arguments.fromURI#";
			amzHeaders[ "x-amz-acl" ] 			= arguments.acl;

			// Headers
			headers[ "Content-Length" ] = 0;

			// Invoke call
			var results = S3Request(
				method 		= "PUT",
				resource 	= arguments.toBucket & "/" & arguments.toURI,
				metaHeaders = metaHeaders,
				headers 	= headers,
				amzHeaders 	= amzHeaders
			);

			// error
			if( results.error ){
				throw( message="Error making Google REST call", detail=results.message );
			}

			if( results.responseheader.status_code eq "204"){ return true; }

			return false;
	}

	/* Rename Object 
	 * Renames an object by copying then deleting original.
	*/
	public boolean function renameObject(
		string oldBucketName
		,string oldFileKey
		,string newBucketName
		,string newFileKey
	){
		if(compare( arguments.oldBucketName,arguments.newBucketName ) or compare( arguments.oldFileKey, arguments.newFileKey )){
			copyObject( arguments.oldBucketName, arguments.oldFileKey, arguments.newBucketName, arguments.newFileKey );
			deleteObject( arguments.oldBucketName, arguments.oldFileKey );
			return true;
		}
		else
			return false;
	}

	/*---------------------------------------- PRIVATE ---------------------------------------*/

	/* S3Request 
	 * Invoke an Google REST call
	 * @method.hint The HTTP method to invoke
	 * @resource.hint The resource to hit in the amazon s3 service.
	 * @body.hint The body content of the request if passed.
	 * @headers.hint A struct of HTTP headers to send
	 * @amzHeaders.hint A struct of amz header name-value pairs to send
	 * @parameters.hint A struct of HTTP URL parameters to send in the request
	 * @timeout.hint The default call timeout
	 */
    private struct function S3Request(
    	string method="GET"
    	,string resource=""
    	,any body =""
    	,struct headers={}
    	,struct amzHeaders={}
    	,struct parameters={}
    	,numeric timeout=20
    ){
		var results = {
			error 			= false,
			response 		= {},
			message 		= "",
			responseheader 	= {}
		};
		var HTTPResults = "";
		var timestamp = GetHTTPTimeString( Now() );
		var param = "";
		var md5 = "";
		var amz = "";
		var sortedAMZ = listToArray( listSort( structKeyList( arguments.amzHeaders ), "textnocase" ) );

		// Default Content Type
		if( NOT structKeyExists( arguments.headers, "content-type" ) ){
			arguments.headers[ "content-type" ] = "";
		}

		// Prepare amz headers in sorted order
		for(var x=1; x lte ArrayLen( sortedAMZ ); x++){
			// Create amz signature string
			arguments.headers[ sortedAMZ[ x ]] = arguments.amzHeaders[sortedAMZ[ x ]];
			amz = amz & "\n" & sortedAMZ[ x ] & ":" & arguments.amzHeaders[sortedAMZ[ x ]];
		}

		// Create Signature
		var signature = "#arguments.method#\n#md5#\n#arguments.headers['content-type']#\n#timestamp##amz#\n/#arguments.resource#";
		log.debug( "Prepared Signature: #signature#" );
		signature = createSignature( signature );

		/* REST CAll */
	    var httpService = new http(); 
	    httpService.setMethod(arguments.method); 
	    httpService.setCharset("utf-8"); 
	    httpService.setUrl("#variables.URLEndPoint#/#arguments.resource#");
	    httpService.settimeout(arguments.timeout);

		
		/* Amazon Global Headers  */
	    httpService.addParam(type="header", name="Date", value="#timestamp#");
	    httpService.addParam(type="header", name="Authorization", value="AWS #variables.accessKey#:#signature#");

		/* Headers */
		for(var param in arguments.headers)
		    httpService.addParam(type="header", name="#param#", value="#arguments.headers[param]#");

		/* URL Parameters: encoded automatically by CF */
		for(var param in arguments.parameters)
		    httpService.addParam(type="URL", name="#param#", value="#arguments.parameters[param]#");


		/* Body */
		if (len(arguments.body))
		    httpService.addParam(type="body", value="#arguments.body#");
		 
	    HTTPResults = httpService.send().getPrefix();

		// Log
		log.debug( "Google REST call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signature#", HTTPResults );

		// Set Results
		results.response 		= HTTPResults.fileContent;
		results.responseHeader 	= HTTPResults.responseHeader;
		// Error Detail
		results.message = HTTPResults.errorDetail;
		if( len( HTTPResults.errorDetail ) ){ results.error = true; }

		// Check XML Parsing?
		if( structKeyExists( HTTPResults.responseHeader, "content-type" ) AND
		    HTTPResults.responseHeader["content-type"] eq "application/xml" AND
			isXML( HTTPResults.fileContent ) 
		){
			results.response = XMLParse( HTTPResults.fileContent );
			// Check for Errors
			if( NOT listFindNoCase( "200,204", HTTPResults.responseHeader.status_code ) ){
				// check error xml
				results.error 	= true;
				results.message = "Code: #results.response.error.code.XMLText#. Message: #results.response.error.message.XMLText#";
			}
		}

		return results;
	}
	

	/* HMAC Encryption 
	 * NSA SHA-1 Algorithm: RFC 2104HMAC-SHA1
	 */
	private binary function HMAC_SHA1(
		string signKey
		,string signMessage
	){
		var jMsg = JavaCast( "string", arguments.signMessage ).getBytes( encryption_charset );
		var jKey = JavaCast( "string", arguments.signKey ).getBytes( encryption_charset );
		var key = createObject( "java", "javax.crypto.spec.SecretKeySpec" ).init( jKey,"HmacSHA1" );
		var mac = createObject( "java", "javax.crypto.Mac" ).getInstance( key.getAlgorithm() );

		mac.init( key );
		mac.update( jMsg );

		return mac.doFinal();
	}

}
