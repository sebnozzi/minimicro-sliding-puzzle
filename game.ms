
sprd = display(4)

img = file.loadImage("game-images/musicians.jpg")
imgWidth = img.width
imgHeight = img.height

// Define board properties
colCount = 3
rowCount = 2

cellMargin = 2

// Define Position class
Position = {}
Position.col = 0
Position.row = 0
// Return screen coordinate X
Position.x = function
	x = board.boardLeft + board.cellWidth * (self.col-1) + board.cellWidth / 2
	// Correct for cell margins
	x = x + (self.col * cellMargin)
	return x
end function
// Return screen coordinate Y
Position.y = function
	y = board.boardBottom + board.cellHeight * (self.row-1) + board.cellHeight / 2
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
	for cellSprite in board.cellSprites
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

// Define UI elements

buttonHeight = 33

drawButton = function(label,width,px=null)
	if not px then px = gfx
	px.clear
	px.fillRect 0,0,width,buttonHeight,color.gray
	px.print label,11,2,color.black,"normal"
	px.print label,10,3,color.white,"normal"
end function

// Draws a button image offscreen and returns the resulting image
getButtonImage = function(label,width)
	px = new PixelDisplay
	drawButton label,width,px
	img = px.getImage(0,0,width,buttonHeight)
	return img
end function

getResetButtonImg = function
	img = getButtonImage("Reset",90)
	return img
end function

getShuffleButtonImg = function
	img = getButtonImage("Shuffle",120)
	return img
end function

makeButtonSprite = function(label,width)
	// Create button image
	img = getButtonImage(label,width)
	// Create and set-up sprite
	s = new Sprite
	s.image = img
	s.localBounds = new Bounds
	s.localBounds.width = img.width
	s.localBounds.height = img.height
	// Put into screen
	sprd.sprites.push s
	s.y = board.boardHeight + 40
	// Return it
	return s
end function

UI = {}
UI.init = function(board)
	self.shuffleButton = makeButtonSprite("Shuffle",120)
	self.shuffleButton.x = board.boardLeft + 65
	
	self.resetButton = makeButtonSprite("Reset",90)
	self.resetButton.x = board.boardLeft + board.boardWidth - 50
	
	self.lessButton = makeButtonSprite("<",40)
	self.lessButton.x = board.boardLeft + 300
	
	self.moreButton = makeButtonSprite(">",40)
	self.moreButton.x = board.boardLeft + 500
end function

// Define board

board = {}
// Initialize board
board.init = function(colCount=3,rowCount=2)
	self.initGeometry(colCount,rowCount)
	self.initTiles
end function
// Initialize geometry aspects of the board
// For example: width / height, position, tile size
board.initGeometry = function(colCount,rowCount)
	self.colCount = colCount
	self.rowCount = rowCount
	
	// Define board dimensions and location, 
	// taking into account the pixels needed for cell marings
	self.boardWidth = imgWidth + (1 + self.colCount) * cellMargin
	self.boardHeight = imgHeight + (1 + self.rowCount) * cellMargin
	self.boardLeft = floor(960 / 2 - self.boardWidth / 2)
	// Move a bit to the bottom to accommodate the UI elements
	self.boardBottom = floor(640 / 2 - self.boardHeight / 2) - 20
	
	self.cellWidth = floor(img.width / self.colCount)
	self.cellHeight = floor(img.height / self.rowCount)		
end function
board.initTiles = function
	self.cellSprites = []
	
	// Split image into sprites
	for rowIdx in range(self.rowCount-1,0)
		for colIdx in range(0,self.colCount-1)
			// Get image part
			x = self.cellWidth*colIdx
			y = self.cellHeight*rowIdx
			imagePart = img.getImage(x,y,self.cellWidth,self.cellHeight)
			// Create cell sprite
			cellSprite = newCellSprite(imagePart,colIdx+1,rowIdx+1)
			self.cellSprites.push cellSprite
		end for
	end for
	
	// Place them on screen
	for cellSprite in self.cellSprites
		sprd.sprites.push cellSprite
		cellSprite.updateCoordinates
	end for
	
	// Make the bottom-right sprite the "pivot" sprite
	// It will be "hidden", appearing as the "hole" in which
	// other sprites move in - in reality swapping places
	// with it.
	// At the end, when the puzzle is solved it will be 
	// revealed back.
	self.pivot = self.cellSprites[len(self.cellSprites)-1]
end function

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
board.puzzleIsSolved = function
	for cs in self.cellSprites
		if not cs.isAtInitialPosition then
			return false
		end if
	end for
	return true
end function

// Shuffle pieces by repeatedly applying a random move
board.makeRandomMove = function
	tileToMove = null
	randomOp = floor(rnd * 4)
	if randomOp == 0 then
		tileToMove = self.pivot.neighbourBelow
	else if randomOp == 1 then
		tileToMove = self.pivot.neighbourAbove
	else if randomOp == 2 then
		tileToMove = self.pivot.neighbourRight
	else if randomOp == 3 then
		tileToMove = self.pivot.neighbourLeft
	end if	
	swapPositions(tileToMove,self.pivot)
end function

board.shufflePieces = function
	for i in range(0,50)
		self.makeRandomMove
	end for
	self.pivot.hide
end function

// Bring tiles to their original positions
board.resetPositions = function
	for tile in self.cellSprites
		tile.resetPosition
	end for
	self.pivot.show
end function

// === Game logic ===

playing = false

wasDown = false
isDown = false

clear

board.init
UI.init(board)

while true
	tileToMove = null
	
	// Process keys
	if key.available then
		k = key.get
		if key.pressed("up") then
			tileToMove = board.pivot.neighbourBelow
		else if key.pressed("down") then
			tileToMove = board.pivot.neighbourAbove
		else if key.pressed("left") then
			tileToMove = board.pivot.neighbourRight
		else if key.pressed("right") then
			tileToMove = board.pivot.neighbourLeft
		else if key.pressed("q") then
			exit
		end if		
	end if
	
	// Process mouse clicks
	isDown = mouse.button(0)
	if not wasDown and isDown then
		// Process clicks on tiles
		for c in board.cellSprites
			if c.contains(mouse) and c.isNeighbourOf(board.pivot) then
				tileToMove = c
			end if
		end for
		// Process clicks on buttons
		if UI.resetButton.contains(mouse) then
			board.resetPositions
			playing = false
		else if UI.shuffleButton.contains(mouse) then
			board.shufflePieces
			playing = true
		end if
	end if
	wasDown = isDown
	
	// If there is a tile to move, swap positions with 
	// the pivot
	if tileToMove then
		swapPositions tileToMove,board.pivot 
	end if
	
	// Detect if puzzle is solved
	// If so, reveal the pivot tile
	if board.puzzleIsSolved then
		board.pivot.show
		if playing then
			// Solved!
			playing = false
		end if
	end if
	
	yield
end while