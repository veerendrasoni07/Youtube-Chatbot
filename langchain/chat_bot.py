from langchain_huggingface import HuggingFaceEndpoint,HuggingFaceEmbeddings,ChatHuggingFace
from dotenv import load_dotenv
from pytube import extract
import os
load_dotenv()
from fastapi import FastAPI,HTTPException
from pydantic import BaseModel
from langchain_core.documents import Document
from langchain_core.runnables import RunnableParallel,RunnableLambda,RunnablePassthrough
from langchain_core.prompts import PromptTemplate
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from youtube_transcript_api import YouTubeTranscriptApi
from langchain_core.output_parsers import StrOutputParser


# Things that are going to be GLobal
# llm , model prompt 


app = FastAPI()

llm = HuggingFaceEndpoint(
    repo_id="mistralai/Mistral-7B-Instruct-v0.2",
    task="text-generation"
)

youtube = YouTubeTranscriptApi()

splitter = RecursiveCharacterTextSplitter(chunk_size=1000,chunk_overlap=200)

model = ChatHuggingFace(llm=llm)
embeddings = HuggingFaceEmbeddings()
parser = StrOutputParser()

template = PromptTemplate(
    template="You are a helpful assistant that answers questions about the content of a YouTube video. Make sure to give appropriate and concise answers based on the context, and if you don't about the question then politely say you don't know.\n\n{context}\n\nQuestion: {question}\nAnswer:",
    input_variables=["context", "question"]
)


class LinkRequest(BaseModel):
    link:str

class ChatRequest(BaseModel):
    message:str
    session_id:str

class Response(BaseModel):
    res:str





# EXTRACT VIDEO ID FROM VIDEO URL
def extractVideoIdFromUrl(videoUrl):
    video_id = extract.video_id(videoUrl)
    return video_id


# GENERATE TRANSCRIPT AND FORMAT IT CORRECTLY
def generateTranscript(video_id):
    fetched_trans = youtube.fetch(video_id=video_id,languages=['en','hi','fr','de','es','it','pt','ru','ja','ko','zh-CN','zh-TW','ar','tr','nl','sv','no','da','fi','pl','cs','hu','ro','el','he','th','vi','ms','id','fa','ur','bn','gu','kn','ml','mr','ne','or','pa','si','ta','te','tl','as','am','az','be','bg','ca','cy','eo','eu','ga','gl','hy','ia','ka','kk','km','ku','lt','lv','mi','mn','my','mt','myv','nep','oc','ps','qu','rw','srd','si','so','sq','su','sw','syr','ta','te','tg','ti','tk','tl','tm','tn','to','ts','tt','tum','twi','tyv','ug','vep','wa','wo','xal','xho','xmf','xog','yor','yue','zaz','zea','zh','zu'])
    transcript = " ".join(script.text for script in fetched_trans)
    return transcript


# CREATE DOCUMENT AND SPLIT IT IN CHUNKS 
def splitDoc(transcipt):
    chunks = splitter.create_documents([transcipt])
    return chunks


def retrieve_textFunction(retrieved_doc):
    retrieved_text = "\n".join(doc.page_content for doc in retrieved_doc)
    return retrieved_text

    
    

@app.post('/api/generate-transcript')
async def transcript(data:LinkRequest):

    try:
        video_id = extractVideoIdFromUrl(data.link)
        trans = generateTranscript(video_id=video_id)
        chunks = splitDoc(transcipt=trans)
        
        vector = FAISS.from_documents(
            documents=chunks,
            embedding=embeddings
        )
        os.makedirs(name="vectors",exist_ok=True)

        vector.save_local(f"vectors/{video_id}")

        return {
            "session_id":video_id,
            "message":"Video Processes Successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



@app.post('/api/chat')
async def chat(data:ChatRequest):
    try:
        vector_store = FAISS.load_local(
            f"vectors/{data.session_id}",
            embeddings=embeddings,
            allow_dangerous_deserialization=True
        )
        retriever = vector_store.as_retriever(search_type="similarity",search_kwargs={"k":2})
        retrieved_doc = retriever.invoke(data.message)
        retrieved_text = retrieve_textFunction(retrieved_doc=retrieved_doc)
        simple_chain = template | model | parser
        result = simple_chain.invoke({
            "context":retrieved_text,
            "question":data.message
        })

        return {
            "result": result
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))























