from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text, DateTime, JSON, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    favorites = relationship("UserFavorite", back_populates="user")
    installed_widgets = relationship("InstalledWidget", back_populates="user")

class WidgetListing(Base):
    __tablename__ = "widget_listings"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=False)
    category = Column(String, index=True)  # e.g., "productivity", "entertainment", "health"
    author = Column(String, nullable=False)
    version = Column(String, default="1.0.0")
    price = Column(Float, default=0.0)  # 0 for free widgets
    config_schema = Column(JSON, nullable=False)  # JSON schema for widget configuration
    preview_image_url = Column(String)
    download_count = Column(Integer, default=0)
    rating = Column(Float, default=0.0)
    review_count = Column(Integer, default=0)
    is_featured = Column(Boolean, default=False)
    is_approved = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    favorites = relationship("UserFavorite", back_populates="listing")
    installed_instances = relationship("InstalledWidget", back_populates="listing")

class UserFavorite(Base):
    __tablename__ = "user_favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    listing_id = Column(Integer, ForeignKey("widget_listings.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="favorites")
    listing = relationship("WidgetListing", back_populates="favorites")

class InstalledWidget(Base):
    __tablename__ = "installed_widgets"
    
    id = Column(String, primary_key=True, index=True)  # UUID from Flutter app
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    listing_id = Column(Integer, ForeignKey("widget_listings.id"), nullable=False)
    name = Column(String, nullable=False)
    config = Column(JSON, nullable=False)  # User's custom configuration
    is_enabled = Column(Boolean, default=True)
    placement = Column(String)  # "homescreen", "overlay", "lock_screen"
    last_used = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="installed_widgets")
    listing = relationship("WidgetListing", back_populates="installed_instances")
    usage_stats = relationship("WidgetUsage", back_populates="widget")

class WidgetUsage(Base):
    __tablename__ = "widget_usage"
    
    id = Column(Integer, primary_key=True, index=True)
    widget_id = Column(String, ForeignKey("installed_widgets.id"), nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    event_type = Column(String)  # "open", "interact", "customize"
    duration_seconds = Column(Integer, nullable=True)
    data = Column(JSON, nullable=True)  # Additional event data
    
    # Relationships
    widget = relationship("InstalledWidget", back_populates="usage_stats")