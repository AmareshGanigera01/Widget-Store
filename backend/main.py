from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials, OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
import os
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from dotenv import load_dotenv

from database import get_db, engine
import models
import schemas
import crud

# Load environment variables
load_dotenv()

# Create database tables
models.Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title="Widget Marketplace API",
    description="Backend API for Android Widget Marketplace & Overlay Platform",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# Security
security = HTTPBearer()

# Helper functions for authentication
def verify_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
        token_data = schemas.TokenData(username=email)
    except JWTError:
        raise credentials_exception
    user = crud.get_user_by_email(db, email=token_data.username)
    if user is None:
        raise credentials_exception
    return user

@app.get("/")
async def root():
    return {"message": "Widget Marketplace API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# User endpoints
@app.post("/users/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    return crud.create_user(db=db, user=user)

@app.get("/users/{user_id}", response_model=schemas.User)
def read_user(user_id: int, db: Session = Depends(get_db)):
    db_user = crud.get_user(db, user_id=user_id)
    if db_user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return db_user

# Widget listing endpoints
@app.get("/listings/", response_model=List[schemas.WidgetListing])
def read_listings(
    skip: int = 0, 
    limit: int = 100,
    category: Optional[str] = None,
    db: Session = Depends(get_db)
):
    listings = crud.get_listings(db, skip=skip, limit=limit, category=category)
    return listings

@app.post("/listings/", response_model=schemas.WidgetListing)
def create_listing(
    listing: schemas.WidgetListingCreate,
    db: Session = Depends(get_db)
):
    return crud.create_listing(db=db, listing=listing)

@app.get("/listings/{listing_id}", response_model=schemas.WidgetListing)
def read_listing(listing_id: int, db: Session = Depends(get_db)):
    db_listing = crud.get_listing(db, listing_id=listing_id)
    if db_listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found"
        )
    return db_listing

@app.put("/listings/{listing_id}", response_model=schemas.WidgetListing)
def update_listing(
    listing_id: int,
    listing: schemas.WidgetListingUpdate,
    db: Session = Depends(get_db)
):
    db_listing = crud.update_listing(db, listing_id=listing_id, listing=listing)
    if db_listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found"
        )
    return db_listing

@app.delete("/listings/{listing_id}")
def delete_listing(listing_id: int, db: Session = Depends(get_db)):
    success = crud.delete_listing(db, listing_id=listing_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found"
        )
    return {"message": "Listing deleted successfully"}

# User favorites
@app.post("/users/{user_id}/favorites/{listing_id}")
def add_favorite(
    user_id: int,
    listing_id: int,
    db: Session = Depends(get_db)
):
    return crud.add_user_favorite(db, user_id=user_id, listing_id=listing_id)

@app.delete("/users/{user_id}/favorites/{listing_id}")
def remove_favorite(
    user_id: int,
    listing_id: int,
    db: Session = Depends(get_db)
):
    success = crud.remove_user_favorite(db, user_id=user_id, listing_id=listing_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Favorite not found"
        )
    return {"message": "Favorite removed successfully"}

@app.get("/users/{user_id}/favorites/", response_model=List[schemas.WidgetListing])
def get_favorites(user_id: int, db: Session = Depends(get_db)):
    return crud.get_user_favorites(db, user_id=user_id)

# Authentication endpoints
@app.post("/api/auth/login", response_model=schemas.Token)
async def login_for_access_token(form_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, email=form_data.email)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/api/auth/register", response_model=schemas.Token)
async def register_user(register_data: schemas.RegisterRequest, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = crud.get_user_by_email(db, email=register_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create new user
    user_create = schemas.UserCreate(
        email=register_data.email,
        name=register_data.name,
        password=register_data.password
    )
    
    # Create user with hashed password
    hashed_password = get_password_hash(register_data.password)
    db_user = models.User(
        email=register_data.email,
        name=register_data.name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Generate token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": db_user.email}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

# Sync endpoints
@app.post("/api/sync/push")
async def sync_push(
    sync_data: schemas.SyncPushRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # In a real implementation, you would:
    # 1. Validate and process the incoming data
    # 2. Store it in the database associated with the user
    # 3. Handle conflicts and merging
    
    # For now, we'll just acknowledge receipt
    print(f"Received sync data for user {current_user.id}:")
    print(f"- Widgets: {len(sync_data.widgets)}")
    print(f"- Notebooks: {len(sync_data.notebooks)}")
    print(f"- Entries: {len(sync_data.entries)}")
    
    # Store sync data in a simple JSON format for now
    # In production, you'd want to properly parse and store in relational tables
    sync_record = models.WidgetUsage(
        widget_id="sync_data",  # Using widget_usage table for sync records
        event_type="cloud_sync_push",
        data={
            "user_id": current_user.id,
            "widgets": sync_data.widgets,
            "notebooks": sync_data.notebooks,
            "entries": sync_data.entries,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    db.add(sync_record)
    db.commit()
    
    return {"message": "Sync data received", "status": "success"}

@app.get("/api/sync/pull", response_model=schemas.SyncPullResponse)
async def sync_pull(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # In a real implementation, you would:
    # 1. Fetch all data associated with this user
    # 2. Return it in the appropriate format
    
    # For now, we'll return sample data structure
    # Get the latest sync record for this user
    latest_sync = db.query(models.WidgetUsage).filter(
        models.WidgetUsage.widget_id == "sync_data",
        models.WidgetUsage.event_type == "cloud_sync_push"
    ).order_by(models.WidgetUsage.timestamp.desc()).first()
    
    if latest_sync and latest_sync.data:
        # Return the stored data
        sync_data = latest_sync.data
        return schemas.SyncPullResponse(
            widgets=sync_data.get("widgets", []),
            notebooks=sync_data.get("notebooks", []),
            entries=sync_data.get("entries", [])
        )
    
    # Return empty response if no sync data exists
    return schemas.SyncPullResponse()

# Protected endpoint example
@app.get("/api/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user