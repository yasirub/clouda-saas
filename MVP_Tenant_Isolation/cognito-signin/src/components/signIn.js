import React,{useState} from "react"
import { CognitoUser,AuthenticationDetails } from "amazon-cognito-identity-js"
import UserPool from "../UserPool"
const SignIn = ()=>{
    const [email,setEmail] = useState("")
    const [password,setPassword] = useState("")
    const onSubmit = (event)=>{
        event.preventDefault();
        const user = new CognitoUser({
            Username: email,
            Pool: UserPool
        })
        const authDetails = new AuthenticationDetails({
            Username: email,
            Password:password,
        })
        user.authenticateUser(authDetails,{
            onSuccess:(data)=>{
                console.log("onSuccess: ",data)
            },
            onFailure:(err)=>{
                console.log("onFailure: ",err)
            },
            newPasswordRequired:(data)=>{
                console.log("newPasswordRequired: ",data)
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
                <button type="submit">SignIn</button>
            </form>
        </div>
    )
}
export default SignIn