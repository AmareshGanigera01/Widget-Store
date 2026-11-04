from sqlalchemy.orm import Session
from sqlalchemy import and_
import models
import schemas
from passlib.context import CryptContext

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# User CRUD operations
def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        name=user.name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# Widget Listing CRUD operations
def get_listings(db: Session, skip: int = 0, limit: int = 100, category: str = None):
    query = db.query(models.WidgetListing).filter(models.WidgetListing.is_approved == True)
    if category:
        query = query.filter(models.WidgetListing.category == category)
    return query.offset(skip).limit(limit).all()

def get_listing(db: Session, listing_id: int):
    return db.query(models.WidgetListing).filter(models.WidgetListing.id == listing_id).first()

def create_listing(db: Session, listing: schemas.WidgetListingCreate):
    db_listing = models.WidgetListing(**listing.dict())
    db.add(db_listing)
    db.commit()
    db.refresh(db_listing)
    return db_listing

def update_listing(db: Session, listing_id: int, listing: schemas.WidgetListingUpdate):
    db_listing = get_listing(db, listing_id)
    if not db_listing:
        return None
    
    update_data = listing.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_listing, field, value)
    
    db.commit()
    db.refresh(db_listing)
    return db_listing

def delete_listing(db: Session, listing_id: int):
    db_listing = get_listing(db, listing_id)
    if not db_listing:
        return False
    
    db.delete(db_listing)
    db.commit()
    return True

def increment_download_count(db: Session, listing_id: int):
    db_listing = get_listing(db, listing_id)
    if db_listing:
        db_listing.download_count += 1
        db.commit()
        db.refresh(db_listing)
    return db_listing

# User Favorites CRUD operations
def add_user_favorite(db: Session, user_id: int, listing_id: int):
    # Check if favorite already exists
    existing = db.query(models.UserFavorite).filter(
        and_(
            models.UserFavorite.user_id == user_id,
            models.UserFavorite.listing_id == listing_id
        )
    ).first()
    
    if existing:
        return existing
    
    db_favorite = models.UserFavorite(user_id=user_id, listing_id=listing_id)
    db.add(db_favorite)
    db.commit()
    db.refresh(db_favorite)
    return db_favorite

def remove_user_favorite(db: Session, user_id: int, listing_id: int):
    db_favorite = db.query(models.UserFavorite).filter(
        and_(
            models.UserFavorite.user_id == user_id,
            models.UserFavorite.listing_id == listing_id
        )
    ).first()
    
    if not db_favorite:
        return False
    
    db.delete(db_favorite)
    db.commit()
    return True

def get_user_favorites(db: Session, user_id: int):
    favorites = db.query(models.UserFavorite).filter(
        models.UserFavorite.user_id == user_id
    ).all()
    
    # Get the actual listings
    listing_ids = [fav.listing_id for fav in favorites]
    return db.query(models.WidgetListing).filter(
        models.WidgetListing.id.in_(listing_ids)
    ).all() if listing_ids else []

# Installed Widgets CRUD operations
def get_installed_widget(db: Session, widget_id: str):
    return db.query(models.InstalledWidget).filter(models.InstalledWidget.id == widget_id).first()

def create_installed_widget(db: Session, widget: schemas.InstalledWidgetCreate):
    db_widget = models.InstalledWidget(**widget.dict())
    db.add(db_widget)
    db.commit()
    db.refresh(db_widget)
    return db_widget

def update_installed_widget(db: Session, widget_id: str, widget_update: schemas.InstalledWidgetUpdate):
    db_widget = get_installed_widget(db, widget_id)
    if not db_widget:
        return None
    
    update_data = widget_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_widget, field, value)
    
    db.commit()
    db.refresh(db_widget)
    return db_widget

def record_widget_usage(db: Session, usage: schemas.WidgetUsageCreate):
    db_usage = models.WidgetUsage(**usage.dict())
    db.add(db_usage)
    db.commit()
    db.refresh(db_usage)
    return db_usage