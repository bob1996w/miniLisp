%{
    #include<iostream>
    #include<cstring>
    #include<vector>
    #include<stdio.h>
    #define MAXITR 100
    using namespace std;
    int yylex(void);
    int yyerror(const char*);
    void errMes(int, string, string);
    static string ext = "";
    static bool debug = false;
    /* static const int maxParam = 100; */
    class Var{
    public:
        Var(string _t, string _n, int _v);
        string name;
        string type;
        int value;
        /*
            for variables,
                name = its name
                type = its type
                value = (func)? function number : its value
            for symbols in ops,
                name = its symbol
                type = "symbol"
                value = how many to count back for operation
            for function, 
                name = its name
                type = "fun"
                value = how many arguments
        */
    };
    Var::Var(string _t, string _n, int _v){
        this->name = _n;
        this->type = _t;
        this->value = _v;
    }
    vector<Var> ids;
    int findId(vector<Var> v, string n){
        int i = 0;
        for(i = 0; i < v.size(); i++){
            if(n == v[i].name){break;}
        }
        if(i == v.size())i = -1;
        return i;
    }
    
    struct returnValue{
        string type;
        int value;
        int errCode;
    };
    class Fun{
    public:
        Fun();
        Fun(string , string );
        vector<Var> par;
        vector<Fun> func;
        vector<Var> body;
        string name;
        string type;
    };
    Fun::Fun(){}
    Fun::Fun(string _t, string _n){
        this->name = _n;
        this->type = _t;
    }
    vector<Fun> calcStack;
    vector<Var> tempId;
    int stp = 0;
%}
%locations
%union{
    int val;
    char* txt;
    struct ExpStruct{
        char* type;
        char* name;
        int value;
    } expStruct;
    struct ExpsStruct{
        char* type[100];
        int value[100];
        int size;
    } expsStruct;
    struct VariableRequest{
        // index < 0  => the variable is not in the ids list.
        int index;
        char* name;
    } varReq;
}
%token<val> NUMBER;
%token<txt> ID;
%token<txt> BOOLVAL;
%token PRINTNUM PRINTBOOL IF MOD AND OR NOT LDEFINE FUN  
%type<expStruct> exp num_op logical_op fun_call if_exp test_exp than_exp else_exp  plus minus multiply divide modulus greater smaller equal and_op or_op not_op param
%type<expsStruct> exp_more
%type<varReq> variable
%type<val> ids ids2 fun_ids
%type<val> params params2
%type<val> fun_exp fun_start
%type<txt> fun_name
%{
// count how many parameters(Var.type == "Id") in a function's par
int parNum(vector<Var> par){
    int num = 0;
    int i = 0;
    for(; i < par.size(); i++){
        if(par[i].type == "Id")num++;
    }
    return num;
}

// for debug: print the stack of vector<Var>
void printStack(vector<Var> vec){
    int i = 0;
    for(; i < vec.size(); i++){
        cout << "[" << vec[i].type << ", " << vec[i].name << ", " << vec[i].value << "] ";
    }
    cout<<endl;
}
// for debug: print the function info
void printFun(Fun func){
    cout<<"Function: "<<func.name<<endl;
    cout<<"    parameters\n    ";
    for(int i = 0; i < func.par.size(); i++)
        cout<<"[" << func.par[i].type << ", " << func.par[i].name << ", " << func.par[i].value << "] ";
    cout<<"\n    func body\n    ";
    for(int i = 0; i < func.body.size(); i++)
        cout<< "[" << func.body[i].type << ", " << func.body[i].name << ", " << func.body[i].value << "] ";
    cout<<endl;
}
// this function checks if all the Vars in [from, until) conforms to _t type.
bool typeCheck(vector<Var> vec, int from, int until, string _t, string extend){
    bool flag = true;
    for(int i = from; i < until; i++){
        if(vec[i].type != _t){
            flag = false;
            // cout<<"typecheck failed "<<extend<<endl;
            ext = vec[i].type;
            break;
        }
    }
    return flag;
}
struct returnValue calc(int now){
    if(debug){cout<<"\n=====calc ["<<now<<"] start=====\n\n";}
    struct returnValue ret;
    ret.errCode = 0;
    int p = 0;
    Fun c = calcStack[now];
    bool notEntered = true;
    int inFunction = 0;
    if(now >= MAXITR){
        errMes(20,"", "");
        ret.errCode = 20;
        return ret;
    }
    if(debug){cout<<"l"<<now<<" p"<<p<<" iF"<<inFunction;printStack(calcStack[now].body);}
    /* cout<<"calcStack["<<now<<"].size = "<<calcStack[now].body.size()<<endl; */
    while(calcStack[now].body.size() > 1 || notEntered  || inFunction > 0){
        int back = 0;
        string t = calcStack[now].body[p].type;
        string n = calcStack[now].body[p].name;
        int t_value = 0;
        string t_type;
        string t_id;
        if((t == "number") || (t == "boolean")){
            p++;
        }
        else if(t == "num_op"){
            int back = calcStack[now].body[p].value;
            p -= back;
            if(!typeCheck(calcStack[now].body, p, p + back, "number", ext)){
                if(n == "+"){
                    errMes(1, ext, "");
                    ret.errCode = 1; break;
                }else if(n == "-"){
                    errMes(2, ext, "");
                    ret.errCode = 2; break;
                }else if(n == "*"){
                    errMes(3, ext, "");
                    ret.errCode = 3; break;
                }else if(n == "/"){
                    errMes(4, ext, "");
                    ret.errCode = 4; break;
                }else if(n == "mod"){
                    errMes(5, ext, "");
                    ret.errCode = 5; break;
                }else if(n == ">"){
                    errMes(6, ext, "");
                    ret.errCode = 6; break;
                }else if(n == "<"){
                    errMes(7, ext, "");
                    ret.errCode = 7; break;
                }else if(n == "="){
                    errMes(8, ext, "");
                    ret.errCode = 8; break;
                }
            }else{
                if(n == "+"){
                    t_value = 0;
                    t_type = "number";
                    int i;
                    for(i = p; i < p + back; i++)
                        t_value += calcStack[now].body[i].value;
                }else if(n == "-"){
                    t_type = "number";
                    t_value = calcStack[now].body[p].value - calcStack[now].body[(p+1)].value;
                }else if(n == "*"){
                    t_type = "number";
                    t_value = 1;
                    int i;
                    for(i = p; i < p + back; i++)
                        t_value *= calcStack[now].body[i].value;
                }else if(n == "/"){
                    if(calcStack[now].body[p+1].value == 0){
                        errMes(9, "", "");
                        ret.errCode = 9; break;
                    }else{
                        t_type = "number";
                        t_value = calcStack[now].body[p].value / calcStack[now].body[(p+1)].value;
                    }
                }else if(n == "mod"){
                    if(calcStack[now].body[p+1].value == 0){
                        errMes(10, "", "");
                        ret.errCode = 10; break;
                    }else{
                        t_type = "number";
                        t_value = calcStack[now].body[p].value % calcStack[now].body[(p+1)].value;
                    }
                }else if(n == ">"){
                    t_type = "boolean";
                    t_value = (calcStack[now].body[p].value > calcStack[now].body[(p+1)].value)? 1 : 0;
                }else if(n == "<"){
                    t_type = "boolean";
                    t_value = (calcStack[now].body[p].value < calcStack[now].body[(p+1)].value)? 1 : 0;
                }else if(n == "="){
                    t_type = "boolean";
                    t_value = (calcStack[now].body[p].value == calcStack[now].body[(p+1)].value)? 1 : 0;
                }
            }
            //if(debug)cout<<"p = "<<p<<", back = "<<back<<endl;
            calcStack[now].body.erase(calcStack[now].body.begin()+p, calcStack[now].body.begin()+(p + back + 1) );
            calcStack[now].body.insert(calcStack[now].body.begin()+p, Var(t_type, "", t_value));
        }
        else if(t == "logical_op"){
            int back = calcStack[now].body[p].value;
            p -= back;
            if(!typeCheck(calcStack[now].body, p, p+back, "boolean", ext)){
                if(n == "and"){
                    errMes(12, ext, "");
                    ret.errCode = 12; break;
                }else if(n == "or"){
                    errMes(13, ext, "");
                    ret.errCode = 13; break;
                }else if(n == "not"){
                    errMes(14, ext, "");
                    ret.errCode = 14; break;
                }
            }else{
                if(n == "and"){
                    t_value = 1;
                    t_type = "boolean";
                    int i;
                    for(i = p; i < p + back; i++)
                        t_value = t_value & calcStack[now].body[i].value;
                }else if(n == "or"){
                    t_value = 0;
                    t_type = "boolean";
                    int i;
                    for(i = p; i < p + back; i++)
                        t_value = t_value | calcStack[now].body[i].value;
                }else if(n == "not"){
                    t_value = (calcStack[now].body[p].value == 0)? 1 : 0;
                    t_type = "boolean";
                }
            }
            calcStack[now].body.erase(calcStack[now].body.begin()+p, calcStack[now].body.begin()+(p+back+1));
            calcStack[now].body.insert(calcStack[now].body.begin()+p, Var(t_type, "", t_value));
        }
        else if(t == "if" && (inFunction <= 0)){ 
            int than_index = calcStack[now].body[p].value;
            int else_index = than_index + 1;
            int back = 1;
            p -= back;
            if(calcStack[now].body[p].type != "boolean"){
                ext = calcStack[now].body[p].type;
                errMes(16, ext, "");
                ret.errCode = 16; break;
            }else{ 
                calcStack[(now+1)].par = calcStack[now].par;
                calcStack[(now+1)].func = calcStack[now].func;
                if(calcStack[now].body[p].value == 1){
                    calcStack[(now+1)].body = calcStack[now].func[than_index].body;
                }else{
                    calcStack[(now+1)].body = calcStack[now].func[else_index].body;
                }
                // if(debug){cout<<"par";printStack(calcStack[(now+1)].par);}
                // if(debug){cout<<"ns";printStack(calcStack[(now+1)].body);}
                struct returnValue _ret = calc(now + 1);
                calcStack[(now+1)].par.clear();
                calcStack[(now+1)].func.clear();
                calcStack[(now+1)].body.clear();
                calcStack[now].body.erase(calcStack[now].body.begin()+p, calcStack[now].body.begin()+(p+back+1));
                calcStack[now].body.insert(calcStack[now].body.begin()+p, Var(_ret.type, "", _ret.value));
                if(_ret.errCode > 0){ret.errCode = _ret.errCode; break;}
            }

        }
        else if(t == "Id" && (inFunction <= 0)){
            int back = calcStack[now].body[p].value;
            p -= back;
            int index = findId(calcStack[now].par, n);
            if(index < 0){
                errMes(18, n, "");
            }else{
                t_value = calcStack[now].par[index].value;
                t_type = calcStack[now].par[index].type;
            }
            calcStack[now].body.erase(calcStack[now].body.begin()+p, calcStack[now].body.begin()+(p+back+1));
            calcStack[now].body.insert(calcStack[now].body.begin()+p, Var(t_type, "", t_value));
        }
        else if(t == "ano_start"){
            inFunction++;
            calcStack[now].body.erase(calcStack[now].body.begin()+p);
        }
        else if(t == "ano_call"){
            inFunction--;
            int index = calcStack[now].body[p].value;
            int back = parNum(calcStack[now].func[index].par);
            p -= back;
            calcStack[(now + 1)].par = calcStack[now].par;
            calcStack[(now + 1)].func = calcStack[now].func;
            vector<Var> _temp;
            for(int i = 0; i < back; i++){
                _temp.push_back(
                    Var( calcStack[(now)].body[(p+i)].type, calcStack[(now+1)].func[index].par[i].name, 
                        calcStack[now].body[(p+i)].value ));
            }
            calcStack[(now+1)].body = calcStack[(now+1)].func[index].body;
            if(debug)printStack(_temp);
            calcStack[(now+1)].par.insert(calcStack[(now+1)].par.begin(), _temp.begin(), _temp.end());
            if(debug){cout<<"par";printStack(calcStack[(now+1)].par);}
            if(debug){cout<<"ns";printStack(calcStack[(now+1)].body);}
            struct returnValue _ret = calc(now + 1);
            calcStack[(now+1)].par.clear();
            calcStack[(now+1)].func.clear();
            calcStack[(now+1)].body.clear();
            calcStack[now].body.erase(calcStack[now].body.begin()+p, calcStack[now].body.begin()+(p+back+1));
            calcStack[now].body.insert(calcStack[now].body.begin()+p, Var(_ret.type, "", _ret.value));
            if(_ret.errCode > 0){ret.errCode = _ret.errCode; break;}
        }
        else if(t == "fun_start"){
            inFunction++;
            calcStack[now].body.erase(calcStack[now].body.begin()+p);
        }
        else if(t == "fun"){
            inFunction--;
            int id_index = findId(calcStack[now].par, calcStack[now].body[p].name);
            if(debug){cout<<"id index="<<id_index<<" ";}
            if(id_index < 0){
                errMes(18, calcStack[now].body[p].name, "");
                ret.errCode = 18; break;
            }
            int index = calcStack[now].par[id_index].value;
            if(debug){
                cout<<"fun_index="<<index<<endl;
                printFun(calcStack[now].func[index]);
            }
            if(parNum(calcStack[0].func[index].par) != calcStack[now].body[p].value){
                if(debug) cout<<"parsize="<<calcStack[0].func[index].par.size()<<", value="<<calcStack[now].body[p].value<<endl;
                errMes(19, calcStack[now].body[p].name, "");
                ret.errCode = 19; break;
            }
            int back = parNum(calcStack[now].func[index].par);
            p -= back;
            // load all variables
            calcStack[(now + 1)].par = calcStack[now].par;
            // load all functions
            calcStack[(now + 1)].func = calcStack[now].func;
            vector<Var> _temp;
            // load the parameters
            for(int i = 0; i < back; i++){
                _temp.push_back(
                    Var( calcStack[(now)].body[(p+i)].type, calcStack[(now+1)].func[index].par[i].name, 
                        calcStack[now].body[(p+i)].value ));
            }
            //load the sub-defines
            for(int i = 0; i < calcStack[now].func[index].par.size(); i++){
                if(calcStack[now].func[index].par[i].type != "Id")
                    _temp.push_back(calcStack[now].func[index].par[i]);
            }
            calcStack[(now+1)].body = calcStack[(now+1)].func[index].body;
            if(debug){cout<<"_temp:";printStack(_temp);}
            calcStack[(now+1)].par.insert(calcStack[(now+1)].par.begin(), _temp.begin(), _temp.end());
            if(debug){cout<<"calcStack[n+1]-parameters:";printStack(calcStack[(now+1)].par);}
            if(debug){cout<<"calcStack[n+1]-body:";printStack(calcStack[(now+1)].body);}
            struct returnValue _ret = calc(now + 1);
            calcStack[(now+1)].par.clear();
            calcStack[(now+1)].func.clear();
            calcStack[(now+1)].body.clear();
            calcStack[now].body.erase(calcStack[now].body.begin()+p, calcStack[now].body.begin()+(p+back+1));
            calcStack[now].body.insert(calcStack[now].body.begin()+p, Var(_ret.type, "", _ret.value));
            if(_ret.errCode > 0){ret.errCode = _ret.errCode; break;}
        }
        else{

        }
        if(debug){cout<<"l"<<now<<" p"<<p<<" iF"<<inFunction;printStack(calcStack[now].body);}
        notEntered = false;
    }
    ret.type = calcStack[now].body[0].type;
    ret.value = calcStack[now].body[0].value;
    calcStack[now].body.erase(calcStack[now].body.begin());
    /* cout<<"calcStack["<<now<<"].size = "<<calcStack[now].body.size()<<endl; */
    if(debug){cout<<"\n=====calc ["<<now<<"] end=====\n\n";}
    return ret;
}
%}
%%
program         : stmts
                ;
stmts           : stmts stmt
                | stmt
                ;
stmt            : exp
                    {
                        struct returnValue ret = calc(stp);
                    }
                | def_stmt
                | print_stmt
                ;
print_stmt      : '(' PRINTNUM exp ')'
                        {
                            struct returnValue ret = calc(stp);
                            if(ret.errCode != 0){return(0);}
                            else{
                                if(ret.type != "number"){
                                    errMes(11, ret.type, "");
                                    YYABORT;
                                }else{
                                    cout<<ret.value<<endl;
                                }
                            }
                        }
                | '(' PRINTBOOL exp ')'
                        {
                            struct returnValue ret = calc(stp);
                            if(ret.errCode != 0){return(0);}
                            else{
                                if(ret.type != "boolean"){
                                    errMes(15, ret.type, "");
                                    YYABORT;
                                }else{
                                    if(ret.value == 0)
                                        cout<<"#f"<<endl;
                                    else
                                        cout<<"#t"<<endl;
                                }
                            }
                        }
                ;
exp_more        : exp_more exp  { $$.size = $1.size + 1; }
                | exp           { $$.size = 1; }
                ;
exp             : BOOLVAL       { $$.type=""; calcStack[stp].body.push_back(Var("boolean", "", (string($1) == "#f")? 0 : 1)); }
                | NUMBER        { $$.type="";calcStack[stp].body.push_back(Var("number", "", $1)); }
                | variable      { $$.type="";calcStack[stp].body.push_back(Var("Id", strdup($1.name), 0)); }
                | num_op        {$$.type="";}
                | logical_op    {$$.type="";}
                | fun_exp       {$$.type = "fun"; $$.value = $1;}
                | fun_call      {$$.type="";}
                | if_exp        {$$.type="";}
                ;
num_op          : plus
                | minus 
                | multiply
                | divide
                | modulus
                | greater
                | smaller
                | equal
                ;
plus            : '(' '+' exp exp_more ')' 
                    { calcStack[stp].body.push_back(Var("num_op", "+", ($4.size + 1))); }
                ;
minus           : '(' '-' exp exp ')' 
                    { calcStack[stp].body.push_back(Var("num_op", "-", 2)); }
                ;
multiply        : '(' '*' exp exp_more ')' 
                    { calcStack[stp].body.push_back(Var("num_op", "*", ($4.size + 1))); }
                ;
divide          : '(' '/'  exp exp ')'
                    { calcStack[stp].body.push_back(Var("num_op", "/", 2)); }
                ;
modulus         : '(' MOD exp exp ')'
                    { calcStack[stp].body.push_back(Var("num_op", "mod", 2)); }
                ;
greater         : '(' '>' exp exp ')'
                    { calcStack[stp].body.push_back(Var("num_op", ">", 2)); }
                ;
smaller         : '(' '<' exp exp ')'
                    { calcStack[stp].body.push_back(Var("num_op", "<", 2)); }
                ;
equal           : '(' '=' exp exp_more ')'
                    { calcStack[stp].body.push_back(Var("num_op", "=", ($4.size + 1))); }
                ;
logical_op      : and_op
                | or_op
                | not_op
                ;
and_op          : '(' AND exp exp_more ')'  
                    { calcStack[stp].body.push_back(Var("logical_op", "and", ($4.size + 1))); }
                ;
or_op           : '(' OR exp exp_more ')'
                    { calcStack[stp].body.push_back(Var("logical_op", "or", ($4.size + 1))); }
                ;
not_op          : '(' NOT exp ')'
                    { calcStack[stp].body.push_back(Var("logical_op", "not", 1)); }
                ;
def_stmt        : LDEFINE variable exp ')'
                    {
                        if(debug)cout<<"def_start"<<endl;
                        if($2.index >= 0){
                            errMes(17, $2.name, calcStack[stp].par[($2.index)].type);
                            return(0);
                        }
                        else if($3.type == "fun"){
                            if(debug)cout<<"define fun: "<<($2.name)<<" at index "<<($3.value)<<endl;
                            calcStack[stp].par.push_back(Var("fun", $2.name, $3.value));
                            if(debug){cout<<"   define.stp="<<stp;printStack(calcStack[stp].par);}
                        }
                        else{
                            struct returnValue ret = calc(stp);
                            calcStack[stp].par.push_back(Var(ret.type, $2.name, ret.value));
                        }
                        if(debug)cout<<"def_end"<<endl;
                    }
                ;
variable        : ID
                        {
                            $$.name = $1;
                            $$.index = findId(calcStack[stp].par, $1);
                        }
                ;
fun_exp         : '(' fun_start fun_ids fun_body ')'
                        {
                            int index = calcStack[0].func.size();
                            calcStack[0].func.push_back(Fun("fun", ""));
                            calcStack[0].func[index].par = calcStack[stp].par;
                            calcStack[0].func[index].body = calcStack[stp].body;
                            calcStack[stp].par.clear();
                            calcStack[stp].body.clear();
                            if(debug){cout<<"fun_exp declared: "<<endl;
                                printFun(calcStack[0].func[index]);
                                cout<<endl;}
                            //tempId.clear();
                            $$ = index;
                            stp--;
                            if(debug){cout<<"end fun_exp"<<endl;}
                        }
                ;
fun_start       : FUN {stp++;}
                ;
ids             : ids2 {$$ = $1;}
                | {$$ = 0;}
                ;
ids2            : ids2 ID {$$ = $1 + 1; calcStack[stp].par.push_back(Var("Id", $2, 0)); }
                | ID    { $$ = 1; calcStack[stp].par.push_back(Var("Id", $1, 0)); }
                ;
fun_ids         : '(' ids ')' {$$ = $2;}
                ;

def_stmts       : def_stmts2
                | 
                ;
def_stmts2      : def_stmts2 def_stmt
                | def_stmt
                ;
fun_body        : def_stmts exp
                ;

/* fun_body        : exp */
params          : params2 { $$ = $1; 
                            if(debug)cout<<"params.size="<<$1<<endl;}
                |       { $$ = 0; }
                ;
params2         : params2 param 
                        { 
                            /* struct returnValue ret = calc(stp); */
                            /* tempId.push_back(Var(ret.type, "param", ret.value)); */
                            $$ = $1 + 1;
                        }
                | param
                        {
                            /* if(debug)cout<<stp;printStack(calcStack[stp].body); */
                            /* struct returnValue ret = calc(stp); */
                            /* tempId.push_back(Var(ret.type, "param", ret.value)); */
                            $$ = 1;
                        }
                ;
fun_call        : '(' fun_exp params ')'
                        {
                            if(debug)cout<<"Fun_call fun_exp"<<endl;
                            if(debug)cout<<"    fun_exp.size = "<<calcStack[stp].func[$2].par.size()<<", params.size = "<<$3<<endl;
                            if(calcStack[stp].func[$2].par.size() != $3){
                                errMes(19, "Anonymous function", "");
                                return(0);
                            } else {
                                calcStack[stp].body.push_back(Var("ano_start", "", 0));
                                //calcStack[stp].body.insert(calcStack[stp].body.end(), tempId.begin(), tempId.end());
                                calcStack[stp].body.push_back(Var("ano_call", "", $2));
                                //tempId.clear();
                            }
                        }
                | '(' fun_name params ')'
                        {
                            if(debug)cout<<"Fun_call named"<<endl;
                            if(debug){cout<<"   stp="<<stp<<", id: ";printStack(calcStack[0].par);}
                            calcStack[stp].body.push_back(Var("fun_start", "", 0));
                            //calcStack[stp].body.insert(calcStack[stp].body.end(), tempId.begin(), tempId.end());
                            calcStack[stp].body.push_back(Var("fun", $2, $3));
                            //tempId.clear();
                        }
                ;
param           : exp
                ;
fun_name        : ID {$$ = $1;}
                ;
if_exp          : '(' IF test_exp than_exp else_exp ')'
                    {
                        if(debug){cout<<"if-body: ";printStack(calcStack[(stp+1)].body);}
                        int than_index = calcStack[0].func.size();
                        int else_index = than_index + 1;
                        calcStack[0].func.push_back(Fun("if", ""));
                        calcStack[0].func.push_back(Fun("if", ""));
                        int splitter = findId(calcStack[(stp+1)].body, "if_split");
                        if(debug){cout<<"   if-splitter="<<splitter<<endl;}
                        calcStack[0].func[than_index].body.assign(calcStack[(stp+1)].body.begin(), calcStack[(stp+1)].body.begin()+splitter);
                        calcStack[0].func[else_index].body.assign(calcStack[(stp+1)].body.begin()+splitter+1, calcStack[(stp+1)].body.end());
                        calcStack[(stp+1)].body.clear();
                        calcStack[stp].body.push_back(Var("if", "", than_index));
                    }
                ;
test_exp        : exp
                    { stp = stp + 1;
                    if(debug){cout<<"if in @ stp: "<<stp<<endl;}}
                ;
than_exp        : exp
                    { calcStack[stp].body.push_back(Var("if_split", "if_split", 0));}
                ;
else_exp        : exp
                    { stp = stp - 1;
                    if(debug){cout<<"if out @ stp: "<<stp<<endl;}}
                ;
%%
int yyerror(const char* message){
    cout<<"Syntax error"<<endl;
}
void errMes(int errCode, string extend, string extend2){
    string mes;
    switch(errCode){
        case  1: mes = "+: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  2: mes = "-: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  3: mes = "*: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  4: mes = "/: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  5: mes = "mod: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  6: mes = ">: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  7: mes = "<: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  8: mes = "=: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case  9: mes = "/: Divided by 0"; break;
        case 10: mes = "mod: Divided by 0"; break;
        case 11: mes = "print-num: Expect \'number\' but got \'" + string(extend) + "\'"; break;
        case 12: mes = "and: Expect \'boolean\' but got \'" + string(extend) + "\'"; break;
        case 13: mes = "or: Expect \'boolean\' but got \'" + string(extend) + "\'"; break;
        case 14: mes = "not: Expect \'boolean\' but got \'" + string(extend) + "\'"; break;
        case 15: mes = "print-bool: Expect \'boolean\' but got \'" + string(extend) + "\'"; break;
        case 16: mes = "if: Expect \'boolean\' but got \'" + string(extend) + "\'"; break;
        case 17: mes = "define: Id \'" + string(extend) + "\' has already been defined as \'"+ string(extend2)+"\'"; break;
        case 18: mes = "Id: \'" + string(extend) + "\' has not been defined"; break;
        case 19: mes = string(extend) + ": arguments number not match"; break;
        case 20: mes = "Calculate stack overflow"; break;
    }
    
    cout << "Error: " << mes << endl;
}
int main(int argc, char *argv[]){
    for(int i = 0; i < argc; i++)
        if(argv[i] == "-d")debug = true;
    for(int i = 0; i < MAXITR; i++){
        calcStack.push_back(Fun());
    }
    yyparse();
    return 0;
}
