import "./App.css"
import { Uploader } from "./utils/upload"
import { useEffect, useState } from "react"

function App() {
  const [file, setFile] = useState(undefined)
  const [pgvalue, setPgvalue] = useState(undefined)
  const [perf,setPerf] = useState(undefined)
  const [baseUrl, setBaseUrl] = useState("https://api.development.oxolo.com/internal/lmc/v1")
  const [authToken, setAuthToken] = useState("ytjUpgXSpEA8LtscFxgfu58c")
  const [basePath,setBasePath] = useState(undefined)

  useEffect(() => {
    if (file) {
      const uploaderOptions = {
        file: file,
        baseURL: baseUrl,
        chunkSize: 5,
        threadsQuantity: 5,
        basePath: basePath,
        authToken: authToken,
      }

      let percentage = undefined
      setPgvalue(0)
      setPerf("-")
      const uploader = new Uploader(uploaderOptions)
      const tBegin=performance.now()
      uploader
        .onProgress(({ percentage: newPercentage }) => {
          // to avoid the same percentage to be logged twice
          if(percentage === 100){
             setPerf((performance.now() - tBegin)/1000)
          }
          if (newPercentage !== percentage) {
            percentage = newPercentage
            setPgvalue(percentage)
          }
        })
        .onError((error) => {
          setFile(undefined)
          console.error(error)
        })

      uploader.start()      
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [file])

  return (
    <div >
      <div style={{ backgroundColor: "#e2e2e2", padding: "20px", margin: "10px"}}>    
        <strong style={{display: "block"}}>Step 1 - Enter API URL</strong><br/>
        <input type="text" id="urlinput" style={{width: "50%"}} placeholder="https://example.execute-api.example.amazonaws.com/example/" 
               onChange={(e) => {
                setBaseUrl(e.target?.value)
               }}
        />
      </div>  
      <div style={{ backgroundColor: "#e2e2e2", padding: "20px", margin: "10px"}}>    
        <strong style={{display: "block"}}>Step 2 - Enter API Key</strong><br/>
        <input type="text" id="urlinput" style={{width: "50%"}} placeholder="12345" 
               onChange={(e) => {
                setAuthToken(e.target?.value)
               }}
        />
      </div>  
      <div style={{ backgroundColor: "#e2e2e2", padding: "20px", margin: "10px"}}>    
        <strong style={{display: "block"}}>Step 2 - Destination File Path</strong><br/>
        <input type="text" id="urlinput" style={{width: "50%"}} placeholder="user_id/media_id" 
               onChange={(e) => {
                setBasePath(e.target?.value)
               }}
        />
      </div>  
      <div style={{ backgroundColor: "#e2e2e2", padding: "20px", margin: "10px"}}>
        <strong style={{display: "block"}}>Step 3 - Choose a file</strong><br/>
        <input type="file" id="fileinput" 
               onChange={(e) => {
                setFile(e.target?.files?.[0])
               }}
        />
      </div>
      <div style={{ backgroundColor: "#e2e2e2", padding: "20px", margin: "10px"}}>
        <strong style={{display: "block"}}>Step 4 - Monitor</strong><br/>
        <span id="output">{pgvalue}% ({perf} sec)</span>
      </div>
    </div>
  )
}

export default App
