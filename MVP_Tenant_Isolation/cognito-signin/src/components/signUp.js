import React,{useState} from "react"
import UserPool from "../UserPool"
const SignUp = ()=>{
    const [email,setEmail] = useState("")
    const [password,setPassword] = useState("")
    const onSubmit = (event)=>{
        event.preventDefault();
        UserPool.signUp(email,password,[],null,(err,result)=>{
            if(err){
                console.log(err)
            }else{
                console.log(result)
            }
        })
    }
    return(
        <div>
            <form onSubmit={onSubmit}>
                <label htmlFor="email">Email</label>
                <input name="email" value={email} onChange={(event)=> setEmail(event.target.value)}/>
                <label htmlFor="password">Password</label>
                <input name="password" value={password} onChange={(event)=> setPassword(event.target.value)}/>
                <button type="submit">SignUp</button>
            </form>
        </div>
    )
}
export default SignUp