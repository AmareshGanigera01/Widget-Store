from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List, Dict, Any
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    email: EmailStr
    name: str

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Widget Listing schemas
class WidgetListingBase(BaseModel):
    name: str
    description: str
    category: Optional[str] = None
    author: str
    version: str = "1.0.0"
    price: float = 0.0
    config_schema: Dict[str, Any]
    preview_image_url: Optional[str] = None
    is_featured: bool = False

class WidgetListingCreate(WidgetListingBase):
    pass

class WidgetListingUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    price: Optional[float] = None
    config_schema: Optional[Dict[str, Any]] = None
    preview_image_url: Optional[str] = None
    is_featured: Optional[bool] = None
    is_approved: Optional[bool] = None

class WidgetListing(WidgetListingBase):
    id: int
    download_count: int
    rating: float
    review_count: int
    is_approved: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Installed Widget schemas
class InstalledWidgetBase(BaseModel):
    id: str  # UUID
    name: str
    config: Dict[str, Any]
    is_enabled: bool = True
    placement: Optional[str] = None

class InstalledWidgetCreate(InstalledWidgetBase):
    user_id: int
    listing_id: int

class InstalledWidget(InstalledWidgetBase):
    user_id: int
    listing_id: int
    last_used: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Widget Usage schemas
class WidgetUsageBase(BaseModel):
    event_type: str
    duration_seconds: Optional[int] = None
    data: Optional[Dict[str, Any]] = None

class WidgetUsageCreate(WidgetUsageBase):
    widget_id: str

class WidgetUsage(WidgetUsageBase):
    id: int
    widget_id: str
    timestamp: datetime
    
    class Config:
        from_attributes = True

# Favorite schemas
class UserFavoriteBase(BaseModel):
    user_id: int
    listing_id: int

class UserFavoriteCreate(UserFavoriteBase):
    pass

class UserFavorite(UserFavoriteBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# Token schemas (for future authentication)
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None