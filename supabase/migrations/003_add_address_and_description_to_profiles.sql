ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS address text;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS shop_description text;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS verified boolean DEFAULT false;

