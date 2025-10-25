import { useState } from 'react'
import { ApiService } from './api'
import NotionTable from './components/NotionTable'

function App() {
  const [apiService] = useState(new ApiService())

  return <NotionTable apiService={apiService} />
}

export default App
