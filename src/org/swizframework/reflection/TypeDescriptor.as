package org.swizframework.reflection
{
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import org.swizframework.metadata.AutowireMetadataTag;
	import org.swizframework.metadata.MediateMetadataTag;
	
	/**
	 * This class is used to store basic information about types that Swiz
	 * needs to know about.
	 */
	public class TypeDescriptor
	{
		// ========================================
		// public properties
		// ========================================
		
		/**
		 * Output of describeType() for this type.
		 */
		public var description:XML;
		
		/**
		 * The fully qualified name of this type.
		 */
		public var className:String;
		
		/**
		 * The fully qualified name of this type's super class.
		 */
		public var superClassName:String;
		
		/**
		 * The fully qualified name of all interfaces this type implements.
		 */
		public var interfaces:Array = [];
		
		/**
		 * Array of IMetadataHost instances for this type.
		 * 
		 * @see org.swizframework.reflection.IMetadataHost
		 */
		public var metadataHosts:Array = [];
		
		// ========================================
		// constructor
		// ========================================
		
		public function TypeDescriptor()
		{
			
		}
		
		// ========================================
		// protected methods
		// ========================================
		
		/**
		 * Gather and return all properties, methods or the class itself that 
		 * are decorated with metadata.
		 */
		protected function getMetadataHosts( description:XML ):Array
		{
			var host:IMetadataHost;
			
			// find all metadata tags in describeType()'s output XML
			// parent node will be the actual property/method/class node
			for each( var mdNode:XML in description..metadata )
			{
				// property, method or class?
				var metadataHostKind:String = mdNode.parent().name();
				// name of property/method
				var metadataHostName:String = mdNode.parent().@name.toString();
				
				// if we don't already have an IMetadataHost object for this property/method
				if( !hasMetadataHostWithName( metadataHostName ) )
				{
					// actual type is determined by metadata's parent tag
					host = ( metadataHostKind == "method" ) ? new MetadataHostMethod()
															: ( metadataHostKind == "type" ) ? new MetadataHostClass()
																							 : new MetadataHostProperty();
					
					// TODO: more temp fix code
					if( host is MetadataHostProperty )
					{
						MetadataHostProperty( host ).type = getDefinitionByName( mdNode.parent().@type.toString() ) as Class;
					}
					
					host.name = metadataHostName;
					metadataHosts.push( host );
				}
				
				// gather and store all key/value pairs for the metadata tag
				var args:Array = [];
				for each( var argNode:XML in mdNode.arg )
				{
					args.push( new MetadataArg( argNode.@key.toString(), argNode.@value.toString() ) );
				}
				
				// create and store metadata tag as object
				//var mt:IMetadataTag = new BaseMetadataTag( mdNode.@name.toString(), args, host );
				// TODO: this is a temp fix
				var tagName:String = mdNode.@name.toString();
				var mt:IMetadataTag = ( tagName == "Autowire" ) ? new AutowireMetadataTag( args, host )
																: ( tagName == "Mediate" ) ? new MediateMetadataTag( args, host )
																							: new BaseMetadataTag( tagName, args, host );
				host.metadataTags.push( mt );
			}
			
			return metadataHosts;
		}
		
		/**
		 * Check to see if this type already has an IMetadataHost with the given name.
		 * 
		 * @see org.swizframework.reflection.IMetadataHost
		 */
		protected function hasMetadataHostWithName( metadataHostName:String ):Boolean
		{
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				if( metadataHost.name == metadataHostName )
				{
					return true;
				}
			}
			
			return false;
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * Populates the TypeDescriptor instance from the data returned
		 * by flash.utils.describeType.
		 * 
		 * @see flash.utils.describeType
		 */
		public function fromXML( description:XML ):TypeDescriptor
		{
			this.description = description;
			className = description.@name;
			superClassName = description.@base;
			for each( var node:XML in description.implementsInterface )
				interfaces.push( node.@type.toString() );
			metadataHosts = getMetadataHosts( description );
			
			return this;
		}
		
		private static var types:Dictionary = new Dictionary();
		
		public function fromInstance( obj:Object ):TypeDescriptor
		{
			var qn:String = getQualifiedClassName( obj );
			if( types[ qn ] != null )
				return types[ qn ];
			
			types[ qn ] = fromXML( describeType( obj ) );
			return types[ qn ];
		}
		
		/**
		 * Determine whether or not this class has any instances of
		 * metadata tags with the provided name.
		 */
		public function hasMetadataTag( metadataTagName:String ):Boolean
		{
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				for each( var metadataTag:IMetadataTag in metadataHost.metadataTags )
				{
					if( metadataTag.name == metadataTagName )
						return true;
				}
			}
			return false;
		}
		
		/**
		 * Get all IMetadataHost instances for this type that are decorated
		 * with metadata tags with the provided name.
		 */
		public function getMetadataHostsWithTag( metadataTagName:String ):Array
		{
			var hosts:Array = [];
			
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				for each( var metadataTag:IMetadataTag in metadataHost.metadataTags )
				{
					if( metadataTag.name == metadataTagName )
					{
						hosts.push( metadataHost );
						continue;
					}
				}
			}
			
			return hosts;
		}
		
		/**
		 * Get all MetadataTag instances for class member with the provided name.
		 */
		public function getMetadataTagsByName( tagName:String ):Array
		{
			var tags:Array = [];
			
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				for each( var metadataTag:IMetadataTag in metadataHost.metadataTags )
				{
					if( metadataTag.name == tagName )
					{
						tags.push( metadataTag );
					}
				}
			}
			
			return tags;
		}
		
		/**
		 * Get all MetadataTag instances for class member with the provided name.
		 */
		public function getMetadataTagsForMember( memberName:String ):Array
		{
			var tags:Array;
			
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				if( metadataHost.name == memberName )
				{
					tags = metadataHost.metadataTags;
				}
			}
			
			return tags;
		}
		
		/**
		 * Return all MetadataHostProperty instances for this type.
		 * 
		 * @see org.swizframework.reflection.MetadataHostProperty
		 */
		public function getMetadataHostProperties():Array
		{
			var hostProps:Array = [];
			
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				if( metadataHost is MetadataHostProperty )
				{
					hostProps.push( metadataHost );
					continue;
				}
			}
			
			return hostProps;
		}
		
		/**
		 * Return all MetadataHostMethod instances for this type.
		 * 
		 * @see org.swizframework.reflection.MetadataHostMethod
		 */
		public function getMetadataHostMethods():Array
		{
			var hostMethods:Array = [];
			
			for each( var metadataHost:IMetadataHost in metadataHosts )
			{
				if( metadataHost is MetadataHostMethod )
				{
					hostMethods.push( metadataHost );
					continue;
				}
			}
			
			return hostMethods;
		}
	}
}