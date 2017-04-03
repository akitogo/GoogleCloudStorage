/**
* This module connects your application to Amazon S3
**/
component {

	// Module Properties
	this.title 				= "Google Cloud Storage";
	this.author 			= "Akitogo Internet and Media Applications GmbH";
	this.webURL 			= "https://www.akitogo.com";
	this.description 		= "This API will provide you with Google Cloud Storage connectivity for any ColdFusion (CFML) application.";
	this.version			= "0.8.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	this.autoMapModels 		= false;

	/**
	 * Configure
	 */
	function configure(){

		// Settings
		settings = {
			accessKey = "",
			secretKey = "",
			encryption_charset = "utf-8",
			ssl = false
		};
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		parseParentSettings();
		var GoogleStorageSettings = controller.getConfigSettings().GoogleStorageSettings;
		
		// Map Google Storage Library
		binder.map( "GoogleStorage@GoogleCloudStorage" )
			.to( "#moduleMapping#.models.GoogleStorage" )
			.initArg( name="accessKey", 			value=GoogleStorageSettings.accessKey )
			.initArg( name="secretKey", 			value=GoogleStorageSettings.secretKey )
			.initArg( name="encryption_charset", 	value=GoogleStorageSettings.encryption_charset )
			.initArg( name="ssl", 					value=GoogleStorageSettings.ssl );
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
	}

	/**
	* parse parent settings
	*/
	private function parseParentSettings(){
		var oConfig 		= controller.getSetting( "ColdBoxConfig" );
		var configStruct 	= controller.getConfigSettings();
		var gcsDSL 			= oConfig.getPropertyMixin( "GoogleCloudStorage", "variables", structnew() );

		//defaults
		configStruct.GoogleStorageSettings = variables.settings;

		// incorporate settings
		structAppend( configStruct.GoogleStorageSettings, gcsDSL, true );
	}

}