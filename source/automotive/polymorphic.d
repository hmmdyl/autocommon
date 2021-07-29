module automotive.polymorphic;

import std.meta : Stride, AliasSeq;
import std.traits : ReturnType, Parameters;

template polymorph(Args...)
{
	struct polymorph
	{
		alias args_ = Args;

		@disable this(this);

		private void* impl;

		static foreach(i, func; Stride!(2, Args))
		{
			// Function pointer
			mixin("public ReturnType!(Args[i * 2]) function(scope void*, Parameters!(func)) " ~ Args[i*2+1] ~ "Impl;"); 
			// Caller
			mixin("public auto " ~ Args[i*2+1] ~ "(AliasSeq!(Parameters!(func)) param) @trusted { return " ~ Args[i*2+1] ~ "Impl(impl, param); }");
		}
	}
}

mixin template derived(alias poly)
{
	static typeof(this)* toMyself(return scope void* impl) @trusted
	{
		return cast(typeof(this)*)impl;
	}

	static poly toPolymorph(return scope typeof(this)* c)
	{
		poly p;
		p.impl = c;

		import std.meta : Stride;
		static foreach(i, func; Stride!(2, poly.args_))
		{
			mixin("p." ~ poly.args_[i*2+1] ~ "Impl = &" ~ poly.args_[i*2+1] ~ "Impl;");
		}
		return p;
	}

	mixin("import std.traits : Parameters;");

	static foreach(i, func; poly.args_)
	{
		static if(i % 2 == 0)
		{
			mixin("static auto " ~ poly.args_[i+1] ~ "Impl(scope void* impl, Parameters!(poly.args_[i]) param) {
			  typeof(this)* me = toMyself(impl);
			  return me." ~ poly.args_[i+1] ~ "(param); }");
		}
	}
}