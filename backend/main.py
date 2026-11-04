from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import List, Optional
import os
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

# Security
security = HTTPBearer()

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