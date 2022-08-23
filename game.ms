
clear
sprd = display(4)

img = file.loadImage("game-images/musicians.jpg")
imgWidth = img.width
imgHeight = img.height

// Define board properties
colCount = 4
rowCount = 4
cellMargin = 2

// Define board dimensions and location, 
// taking into account the pixels needed for cell marings
boardWidth = imgWidth + (1 + colCount) * cellMargin
boardHeight = imgHeight + (1 + rowCount) * cellMargin
boardLeft = floor(960 / 2 - boardWidth / 2)
boardBottom = floor(640 / 2 - boardHeight / 2)

cellWidth = floor(img.width / colCount)
cellHeight = floor(img.height / rowCount)

// Define Position class
Position = {}
Position.col = 0
Position.row = 0
// Return screen coordinate X
Position.x = function
	x = boardLeft + cellWidth * (self.col-1) + cellWidth / 2
	// Correct for cell margins
	x = x + (self.col * cellMargin)
	return x
end function
// Return screen coordinate Y
Position.y = function
	y = boardBottom + cellHeight * (self.row-1) + cellHeight / 2
	// Correct for cell margins
	y = y + (self.row * cellMargin)
	return y
end function
// Return new position with added offset
Position.newWithAddedOffset = function(offsetCol,offsetRow)
	nCol = self.col + offsetCol
	nRow = self.row + offsetRow
	return newPosition(nCol,nRow)
end function


newPosition = function(col,row)
	pos = new Position
	pos.col = col
	pos.row = row
	return pos
end function

// Define CellSprite class
CellSprite = new Sprite
CellSprite.pos = new Position
CellSprite.initialPos = new Position
// Returns true if the current position is the same as
// the initial one
CellSprite.isAtInitialPosition = function
	return self.initialPos == self.pos
end function
// Reset sprite's position to initial one
CellSprite.resetPosition = function
	self.pos = self.initialPos
	self.updateCoordinates
end function
// Show sprite
CellSprite.show = function
	self.tint = color.white
end function
// Hide sprite
CellSprite.hide = function
	self.tint = color.black
end function
// Update sprite's coordinates based on the model col / row
CellSprite.updateCoordinates = function
	self.x = self.pos.x
	self.y = self.pos.y
end function
// Methods to find neighbour cells
CellSprite.neighbourLeft = function
	return self.neighbourAtOffset(-1,0)
end function
CellSprite.neighbourRight = function
	return self.neighbourAtOffset(1,0)
end function
CellSprite.neighbourAbove = function
	return self.neighbourAtOffset(0,1)
end function
CellSprite.neighbourBelow = function
	return self.neighbourAtOffset(0,-1)
end function
CellSprite.neighbourAtOffset = function(deltaCol,deltaRow)
	nPos = self.pos.newWithAddedOffset(deltaCol,deltaRow)
	for cellSprite in cellSprites
		if cellSprite.pos == nPos then
			return cellSprite
		end if
	end for
	// No match found - happens when the sought 
	// neighbour is "offscreen"
	return null
end function
// True if other is neighbour of self
CellSprite.isNeighbourOf = function(other)
	neighbours = [
	  self.neighbourAbove,
	  self.neighbourBelow,
	  self.neighbourLeft,
	  self.neighbourRight ]
	for n in neighbours 
		if n == other then return true
	end for
	return false
end function

// Factory function to create cell sprites
newCellSprite = function(img,col,row)
	s = new CellSprite
	s.image = img
	s.pos = newPosition(col,row)
	s.initialPos = newPosition(col,row)
	bounds = new Bounds
	bounds.width = img.width
	bounds.height = img.height
	s.localBounds = bounds
	return s
end function

// Split image into sprites!

cellSprites = []

for rowIdx in range(rowCount-1,0)
	for colIdx in range(0,colCount-1)
		// Get image part
		x = cellWidth*colIdx
		y = cellHeight*rowIdx
		imagePart = img.getImage(x,y,cellWidth,cellHeight)
		// Create cell sprite
		cellSprite = newCellSprite(imagePart,colIdx+1,rowIdx+1)
		cellSprites.push cellSprite
	end for
end for

// Place the (cell) sprites on the screen

for cellSprite in cellSprites
	sprd.sprites.push cellSprite
	cellSprite.updateCoordinates
end for

// Make the bottom-right sprite the "pivot" sprite
// It will be "hidden", appearing as the "hole" in which
// other sprites move in - in reality swapping places
// with it.
// At the end, when the puzzle is solved it will be 
// revealed back.

pivot = cellSprites[len(cellSprites)-1]
pivot.hide

// Swap positions of cell sprites,
// moving one to the other and vice versa.
swapPositions = function(a,b)
	if a == null or b == null then return
	previousA = a.pos
	// Set a's position to b's
	a.pos = b.pos
	// Set b's to a's
	b.pos = previousA
	// Update screen coordinates of both
	a.updateCoordinates
	b.updateCoordinates
end function

// Returns true if all pieces are in their initial positions
puzzleIsSolved = function
	for cs in cellSprites
		if not cs.isAtInitialPosition then
			return false
		end if
	end for
	return true
end function

// Shuffle pieces by repeatedly applying a random move
makeRandomMove = function
	tileToMove = null
	randomOp = floor(rnd * 4)
	if randomOp == 0 then
		tileToMove = pivot.neighbourBelow
	else if randomOp == 1 then
		tileToMove = pivot.neighbourAbove
	else if randomOp == 2 then
		tileToMove = pivot.neighbourRight
	else if randomOp == 3 then
		tileToMove = pivot.neighbourLeft
	end if	
	swapPositions(tileToMove,pivot)
end function

shufflePieces = function
	for i in range(0,50)
		makeRandomMove
	end for
end function

// Bring tiles to their original positions
resetPositions = function
	for tile in cellSprites
		tile.resetPosition
	end for
end function

// === Game logic ===

shufflePieces

wasDown = false
isDown = false

while true
	tileToMove = null
	
	// Process keys
	if key.available then
		k = key.get
		if key.pressed("up") then
			tileToMove = pivot.neighbourBelow
		else if key.pressed("down") then
			tileToMove = pivot.neighbourAbove
		else if key.pressed("left") then
			tileToMove = pivot.neighbourRight
		else if key.pressed("right") then
			tileToMove = pivot.neighbourLeft
		else if key.pressed("q") then
			exit
		end if		
	end if
	
	// Process mouse clicks
	isDown = mouse.button(0)
	if not wasDown and isDown then
		for c in cellSprites
			if c.contains(mouse) and c.isNeighbourOf(pivot) then
				tileToMove = c
			end if
		end for
	end if
	wasDown = isDown
	
	// If there is a tile to move, swap positions with 
	// the pivot
	if tileToMove then
		swapPositions tileToMove,pivot 
	end if
	
	// Detect if puzzle is solved
	// If so, reveal the pivot tile and exit
	if puzzleIsSolved then
		pivot.show
		print "Solved!"
		exit
	end if
	
	yield
end while