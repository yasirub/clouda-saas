import {CognitoUserPool} from "amazon-cognito-identity-js"

const poolData ={
    UserPoolId: "eu-west-2_ypy2SeovU",
    ClientId: "1uesvdrq9s74v2bsven3vaqm99"
}
export default new CognitoUserPool(poolData);