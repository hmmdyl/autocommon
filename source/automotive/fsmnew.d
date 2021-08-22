module automotive.fsmnew;

import std.traits;

@safe:

template FsmHandler(alias TEnumMember, alias THandler)
{
    private alias TEnumMember_ = TEnumMember;
    private alias THandler_ = THandler;

    static assert(is(typeof(TEnumMember) == enum), "TEnumMember must be a member of an enum");
    static assert(is(typeof(THandler) == function), "THandler must be a function");
    static assert(is(ReturnType!(typeof(THandler)) == typeof(TEnumMember)), "THandler must return " ~ typeof(TEnumMember).stringof);
}

template FsmHandlerEL(alias TEnumMember, alias THandler, alias TOnEnter, alias TOnExit)
{
    private alias TEnumMember_ = TEnumMember;
    private alias THandler_ = THandler;
    private alias TOnEnter_ = TOnEnter;
    private alias TOnExit_ = TOnExit;

    static assert(is(typeof(TEnumMember) == enum), "TEnumMember must be a member of an enum");
    static assert(is(typeof(THandler) == function), "THandler must be a function");
    static assert(is(ReturnType!(typeof(THandler)) == typeof(TEnumMember)), "THandler must return " ~ typeof(TEnumMember).stringof);

    static assert(is(typeof(TOnEnter) == function) || is(typeof(TOnEnter is null)), "TOnEnter must be a function or null");
    static assert(is(typeof(TOnExit) == function) || is(typeof(TOnExit is null)), "TOnExit must be a function or null");
}

private enum TIsNull(alias T) = is(typeof(T is null));

struct FiniteStateMachine(TEnum, alias TContext, Args...) {  
    static assert(is(TContext == struct) || is(typeof(TContext is null)), "TContext must be struct or null");
    private enum ContextIsNull = is(typeof(TContext is null));

	private TEnum previous_, current_, next_;
    @property previous() const { return previous_; }
    @property current() const { return current_; }
    @property next() const { return next_; }

    static if(!ContextIsNull)
    {
        private TContext context_;
        @property ref TContext context() return { return context_; }
        @property void context(const ref TContext newContext) { context_ = newContext; }

        this(TContext context, TEnum initial)
        {
            this.context_ = context;
            this.previous_ = initial;
            this.current_ = initial;
            callEL!true(true);

        }
    }
    else
    {
        this(TEnum initial)
        {
            this.previous_ = initial;
            this.current_ = initial;
            callEL!true(true);
        }
    }

    static foreach(i, arg; Args)
    {
        static if(__traits(isSame, TemplateOf!arg, FsmHandler))
        {
        	static assert(is(ReturnType!(typeof(arg.THandler_)) == TEnum), "Return type of " ~ arg.THandler_.stringof ~ " must be " ~ TEnum.stringof);
        }
        else static if(__traits(isSame, TemplateOf!arg, FsmHandlerEL))
        { 
            static assert(is(ReturnType!(typeof(arg.THandler_)) == TEnum), "Return type of " ~ arg.THandler_.stringof ~ " must be " ~ TEnum.stringof);

        }
        else static assert(false, "Args[ " ~ i ~ "] must template FsmHandler or FsmHandlerEL");
    }

    private void callEL(bool TEnter)(bool fsmStart = false)
    {
        final switch(current_)
        {
            foreach(i, arg; Args)
            {
                static if(__traits(isSame, TemplateOf!arg, FsmHandler))
                {
                    mixin("case arg.TEnumMember_: break;");
                }
                else static if(__traits(isSame, TemplateOf!arg, FsmHandlerEL))
                {
                    static if(TEnter)
                    {
                        static if(!is(typeof(arg.TOnEnter_ is null)))
                        {
                            static if(ContextIsNull)
                                mixin("case arg.TEnumMember_: arg.TOnEnter_(cast(const)previous_, cast(const)fsmStart); break;");
                            else
                                mixin("case arg.TEnumMember_: arg.TOnEnter_(cast(const)previous_, cast(const)fsmStart, context_); break;");
                        }
                        else mixin("case arg.TEnumMember_: break;");
                    }
                    else
                    {
                        static if(!is(typeof(arg.TOnExit_ is null)))
                        {
                            static if(ContextIsNull)
                                mixin("case arg.TEnumMember_: arg.TOnExit_(cast(const)next_); break;");                               
                            else
                        		mixin("case arg.TEnumMember_: arg.TOnExit_(cast(const)next_, context_); break;");
                        }
                        else mixin("case arg.TEnumMember_: break;");
                    }
                }
            }
        }
    }

    void tick()
    {
        previous_ = current_;
        current_ = next_;

        if(current_ != previous_)
            callEL!true;

        final switch(current_)
        {
            foreach(i, arg; Args)
            {
                static if(ContextIsNull)
                	mixin("case arg.TEnumMember_: next_ = arg.THandler_; break;");
                else
                    mixin("case arg.TEnumMember_: next_ = arg.THandler_(context_); break;");
            }
        }

        if(next_ != current_)
            callEL!false;
    }
}