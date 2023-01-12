/*

Cleaning data in SQL queries.

*/


-------------------------------------------------------------------
-- Standardize the date format
-- The date formart right now has timestamp as well.
-- Converting it to just the date.

ALTER TABLE [Nashville Housing Data for Data Cleaning]
Add SaleDateConverted Date;

Update [Nashville Housing Data for Data Cleaning]
SET SaleDateConverted = CONVERT(date,SaleDate)

SELECT SaleDateConverted
FROM master.dbo.[Nashville Housing Data for Data Cleaning]




-------------------------------------------------------------------
-- Populate Property Address Data
-- Some of the property addresses are NULL. Populating them using SELF JOIN.

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM master.dbo.[Nashville Housing Data for Data Cleaning] A
     JOIN master.dbo.[Nashville Housing Data for Data Cleaning] B
       ON A.ParcelID = B.ParcelID
       AND A.UniqueID != B.UniqueID
WHERE A.PropertyAddress IS NULL




-------------------------------------------------------------------
-- Breaking out address in individual columns(Address, City)
-- Both PropertAdress and OwnerAdress have combined information of
-- address, city and state. Breaking them down for usability.

-- using SUBSTRING.

ALTER TABLE [Nashville Housing Data for Data Cleaning]
Add PropertySplitAddress Nvarchar(255);

Update [Nashville Housing Data for Data Cleaning]
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress) -1)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
Add PropertySplitCity Nvarchar(255);

Update [Nashville Housing Data for Data Cleaning]
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM master.dbo.[Nashville Housing Data for Data Cleaning]



-- using PARSENAME.

ALTER TABLE [Nashville Housing Data for Data Cleaning]
Add OwnerSplitAddress Nvarchar(255);

Update [Nashville Housing Data for Data Cleaning]
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'),3)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
Add OwnerSplitCity Nvarchar(255);

Update [Nashville Housing Data for Data Cleaning]
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'),2)

ALTER TABLE [Nashville Housing Data for Data Cleaning]
Add OwnerSplitState Nvarchar(255);

Update [Nashville Housing Data for Data Cleaning]
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'),1)

-- checking to make sure changes are effected in table.
SELECT *
FROM master.dbo.[Nashville Housing Data for Data Cleaning]




-------------------------------------------------------------------
-- Change Y and N to Yes and No in Sold as vacant field
-- A lot of entries are Y and N instead of Yes and No.

-- checking how many Y, N, Yes and No there are.
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM master.dbo.[Nashville Housing Data for Data Cleaning]
GROUP BY SoldAsVacant
ORDER BY 2



Update [Nashville Housing Data for Data Cleaning]
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END




-------------------------------------------------------------------
-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
 ROW_NUMBER() OVER(
     PARTITION BY ParcelID,
     PropertyAddress,
     SalePrice,
     SaleDate,
     LegalReference
     ORDER BY 
      UniqueID
 ) row_number
FROM master.dbo.[Nashville Housing Data for Data Cleaning]
)

DELETE
FROM RowNumCTE
WHERE row_number >1




-------------------------------------------------------------------
-- Delete unused columns.
-- Now that we have split the address, deleting the original addresses.
-- not advisable to do in an actual database.

ALTER TABLE master.dbo.[Nashville Housing Data for Data Cleaning]
DROP COLUMN PropertyAddress, OwnerAddress

