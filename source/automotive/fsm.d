module automotive.fsm;

import automotive.option : Optional;

import std.traits : ReturnType, ParameterStorageClass, ParameterStorageClassTuple;
import std.meta : Stride;

@safe:

private alias EnumsOfHandler(T...) = Stride!(2, T);
private alias FunctionsOfHandler(T...) = Stride!(2, T[1..$]);

private string EnumMemberName(alias T)()
{
	size_t lastDot;
	static foreach(index, character; T.stringof)
		if(character == '.')
			lastDot = index;
	return T.stringof[lastDot + 1 .. $];
}

private mixin template FsmTypeCheck(TEnum, Handlers...)
{
	static assert(is(TEnum == enum), 
				  "TEnum must be an enum!");

	static foreach(e; EnumsOfHandler!Handlers)
		static assert(is(typeof(e) == enum), 
					  "Handlers[0, 2, 4, ... $] must be a member of an enumeration, not " ~ typeof(e).stringof);

	static foreach(f; FunctionsOfHandler!Handlers)
	{
		static assert(is(typeof(f) == function), 
					  "Handlers[1, 3, 5, ... $] must be a function, not " ~ typeof(f).stringof);
        static assert(is(ReturnType!(typeof(f)) == TEnum), 
                      "Handlers[1, 3, 5, ... $] must return " ~ TEnum.stringof ~ ", not " ~ ReturnType!(typeof(f)).stringof);
	}
}

deprecated("Use automotive.fsmnew") struct FiniteStateMachine(TEnum, Handlers...)
{
	mixin FsmTypeCheck!(TEnum, Handlers);

	this(TEnum initial)
	{
		this.target_ = initial;
	}

	private TEnum previous_, current_, target_;
	@property previous() const { return previous_; }
	@property current() const { return current_; }
	@property target() const { return target_; }

	void tick()
	{
		previous_ = current_;
		current_ = target_;

		final switch(current_)
		{
			foreach(i, e; EnumsOfHandler!Handlers)
			{
				mixin("case e: target_ = FunctionsOfHandler!(Handlers)[i](); break;"); 
			}
		}
	}

	void runForever()
	{
		while(true) tick;
	}
}

private mixin template ContextFsmTypeCheck(TContext, Handlers...)
{
	static foreach(f; FunctionsOfHandler!Handlers)
	{
		static assert(ParameterStorageClassTuple!(f).length == 1, 
					  "Only one param allowed for handler.");
        static assert((ParameterStorageClassTuple!(f)[0] & ParameterStorageClass.ref_) == ParameterStorageClass.ref_, 
                      "Handlers[1, 3, 5, ... $] must have a scope ref TContext parameter.");
	}
}

deprecated("Use automotive.fsmnew") struct ContextFiniteStateMachine(TEnum, TContext, Handlers...)
{
	mixin FsmTypeCheck!(TEnum, Handlers);
	mixin ContextFsmTypeCheck!(TContext, Handlers);

	this(TEnum initial)
	{
		this.target_ = initial;
		this.context_ = Optional!(TContext).null_;
	}

	this(TEnum initial, TContext context)
	{
		this.target_ = initial;
		this.context_ = context;
	}

	private TEnum previous_, current_, target_;
	@property previous() const { return previous_; }
	@property current() const { return current_; }
	@property target() const { return target_; }

	private Optional!TContext context_;
	@property ref auto context() scope return { return context_; }

	void tick()
	{
		previous_ = current_;
		current_ = target_;

		final switch(current_)
		{
			foreach(i, e; EnumsOfHandler!Handlers)
			{
				mixin("case e: target_ = FunctionsOfHandler!(Handlers)[i](context_); break;"); 
			}
		}
	}

	void runForever()
	{
		while(true) tick;
	}
}