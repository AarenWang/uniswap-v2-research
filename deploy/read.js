const dotenv = require("dotenv")
dotenv.config()

const INFURA_ENDPOINT=process.env.INFURA_ENDPOINT
const endpoint = 'https://ropsten.infura.io/v3/${INFURA_ENDPOINT}';
const MY_PRIVATE_KEY =  process.env.MY_PRIVATE_KEY

console.log("endpoint="+endpoint);
console.log("MY_PRIVATE_KEY="+MY_PRIVATE_KEY);