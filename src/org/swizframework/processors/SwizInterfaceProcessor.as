package org.swizframework.processors
{
	import org.swizframework.core.Bean;
	import org.swizframework.core.IBeanFactoryAware;
	import org.swizframework.core.IDispatcherAware;
	import org.swizframework.core.IDisposable;
	import org.swizframework.core.IInitializing;
	import org.swizframework.core.ISwiz;
	import org.swizframework.core.ISwizAware;
	
	public class SwizInterfaceProcessor implements IBeanProcessor
	{
		private var swiz:ISwiz;
		
		public function SwizInterfaceProcessor()
		{
		}
		
		public function setUpBean( bean:Bean ):void
		{
			var obj:* = bean.type;
			
			if( obj is ISwizAware )
				ISwizAware( obj ).swiz = swiz;
			if( obj is IBeanFactoryAware )
				IBeanFactoryAware( obj ).beanFactory = swiz.beanFactory;
			if( obj is IDispatcherAware )
				IDispatcherAware( obj ).dispatcher = swiz.dispatcher;
			if( obj is IInitializing )
				IInitializing( obj ).afterPropertiesSet();
		}
		
		public function tearDownBean( bean:Bean ):void
		{
			var obj:* = bean.type;
			
			if( obj is ISwizAware )
				ISwizAware( obj ).swiz = null;
			if( obj is IBeanFactoryAware )
				IBeanFactoryAware( obj ).beanFactory = null;
			if( obj is IDispatcherAware )
				IDispatcherAware( obj ).dispatcher = null;
			if( obj is IDisposable )
				IDisposable( obj ).destroy();
		}
		
		public function init( swiz:ISwiz ):void
		{
			this.swiz = swiz;
		}
		
		public function get priority():int
		{
			return ProcessorPriority.SWIZ_INTERFACE;
		}
	}
}