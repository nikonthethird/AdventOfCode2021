#! /usr/bin/env python3

from collections import deque
from copy import deepcopy
from functools import reduce
from itertools import chain
from sys import maxsize
from typing import Iterable, List, Tuple

Room = List[int]
Rooms = List[Room]
State = Tuple[Rooms, Room, int]

def isRoomSpotOccupied(room: Room, spotIndex: int) -> bool:
    """Ensures that the given spot in the room is occupied."""
    return room[spotIndex] is not None

def isRoomSpotClearForMove(room: Room, spotIndex: int) -> bool:
    """Ensures that all spots above the given one in the room are clear."""
    return all(spot is None for spot in room[0 : spotIndex])

def isRoomInValidCondition(room: Room, roomIndex: int) -> bool:
    """Ensures that the room is filled from the back and with the correct amphipods."""
    fullSpotEncountered = False
    for spot in room:
        if spot is not None: fullSpotEncountered = True
        if fullSpotEncountered and spot != roomIndex: return False
    return True

def areAllRoomsSolved(rooms: Rooms) -> bool:
    """Checks if all the rooms are in order."""
    return all(spot is not None for spot in chain.from_iterable(rooms)) and \
    all(sum(room) == len(room) * roomIndex for (roomIndex, room) in enumerate(rooms))

def getStepCountForCorridorLeftSide(roomIndex: int, roomSpotIndex: int, corridorSpotIndex: int) -> int:
    """Steps in the left side corridor count twice (except last spot in corridor), steps in room count once."""
    return 2 * (roomIndex + 2 - corridorSpotIndex) + roomSpotIndex - (corridorSpotIndex == 0)

def getStepCountForCorridorRightSide(roomIndex: int, roomSpotIndex: int, corridorSpotIndex: int, corridor: Room) -> int:
    """Steps in the right side corridor count twice (except last spot in corridor), steps in room count once."""
    return 2 * (corridorSpotIndex - roomIndex - 1) + roomSpotIndex - (corridorSpotIndex == len(corridor) - 1)

def moveFromRoomIntoCorridorLeftSide(state: State, roomIndex: int, roomSpotIndex: int, newRooms: Rooms) -> Iterable[State]:
    """Moves the amphipod at the given room spot into the left side corridor."""
    for corridorSpotIndex in range(roomIndex + 1, -1 , -1):
        # If this spot in the corridor is already occupied, we can break since this blocks the other spots.
        if isRoomSpotOccupied(state[1], corridorSpotIndex): break
        # Create the new corridor with the amphipod in it. The newRooms parameter already contains a cleared room spot.
        newCorridor = state[1][:]
        newCorridor[corridorSpotIndex] = state[0][roomIndex][roomSpotIndex]
        stepCount = getStepCountForCorridorLeftSide(roomIndex, roomSpotIndex, corridorSpotIndex)
        yield (newRooms, newCorridor, state[2] + stepCount * 10 ** newCorridor[corridorSpotIndex])

def moveFromRoomIntoCorridorRightSide(state: State, roomIndex: int, roomSpotIndex: int, newRooms: Rooms) -> Iterable[State]:
    """Moves the amphipod at the given room spot into the right side corridor."""
    for corridorSpotIndex in range(roomIndex + 2, len(state[1])):
        # If this spot in the corridor is already occupied, we can break since this block the other spots.
        if isRoomSpotOccupied(state[1], corridorSpotIndex): break
        # Create the new corridor with the amphipod in it. The newRooms parameter already contains a cleared room spot.
        newCorridor = state[1][:]
        newCorridor[corridorSpotIndex] = state[0][roomIndex][roomSpotIndex]
        stepCount = getStepCountForCorridorRightSide(roomIndex, roomSpotIndex, corridorSpotIndex, state[1])
        yield (newRooms, newCorridor, state[2] + stepCount * 10 ** newCorridor[corridorSpotIndex])

def moveFromRoomIntoCorridor(state: State) -> Iterable[State]:
    """Moves any suitable amphipod in any room into the corridor."""
    for roomIndex, room in enumerate(state[0]):
        # If the room is already in a valid condition (correct amphipods filling up the end),
        # then there's no need to mess around with it, needlessly moving amphipods.
        if isRoomInValidCondition(room, roomIndex): continue
        for roomSpotIndex in range(len(room)):
            # If the spot in the room is unoccupied, we can continue with the next spot.
            if not isRoomSpotOccupied(room, roomSpotIndex): continue
            # If the spot in the room is blocked by a spot above, we can break since
            # all the remaining spots in the room will be blocked too.
            if not isRoomSpotClearForMove(room, roomSpotIndex): break
            # At this point we know that the amphipod in the spot can potentially be moved.
            newRooms = deepcopy(state[0])
            newRooms[roomIndex][roomSpotIndex] = None
            for corridorLeftSideState in moveFromRoomIntoCorridorLeftSide(state, roomIndex, roomSpotIndex, newRooms):
                yield corridorLeftSideState
            for corridorRightSideState in moveFromRoomIntoCorridorRightSide(state, roomIndex, roomSpotIndex, newRooms):
                yield corridorRightSideState


def moveFromCorridorLeftSideIntoRoom(state: State, roomIndex: int, roomSpotIndex: int, newRooms: Rooms) -> Iterable[State]:
    """Checks for and moves amphipods from the left side corridor of the room into the room."""
    for corridorSpotIndex in range(roomIndex + 1, -1, -1):
        # If this spot in the corridor is free, move to the next one.
        if not isRoomSpotOccupied(state[1], corridorSpotIndex): continue
        # If the spot in the corridor is occupied by an amphipod of the wrong kind, stop since it blocks this corridor side.
        if state[1][corridorSpotIndex] != roomIndex: break
        # Create the new corridor with the amphipod removed from it. The newRooms parameter already contains the filled room spot.
        newCorridor = state[1][:]
        newCorridor[corridorSpotIndex] = None
        stepCount = getStepCountForCorridorLeftSide(roomIndex, roomSpotIndex, corridorSpotIndex)
        yield (newRooms, newCorridor, state[2] + stepCount * 10 ** newRooms[roomIndex][roomSpotIndex])

def moveFromCorridorRightSideIntoRoom(state: State, roomIndex: int, roomSpotIndex: int, newRooms: Rooms) -> Iterable[State]:
    """Checks for and moves amphipods from the right side corridor of the room into the room."""
    for corridorSpotIndex in range(roomIndex + 2, len(state[1])):
        # If this spot in the corridor is free, move to the next one.
        if not isRoomSpotOccupied(state[1], corridorSpotIndex): continue
        # If the spot in the corridor is occupied by an amphipod of the wrong kind, stop since it blocks this corridor side.
        if state[1][corridorSpotIndex] != roomIndex: break
        # Create the new corridor with the amphipod removed from it. The newRooms parameter already contains the filled room spot.
        newCorridor = state[1][:]
        newCorridor[corridorSpotIndex] = None
        stepCount = getStepCountForCorridorRightSide(roomIndex, roomSpotIndex, corridorSpotIndex, state[1])
        yield (newRooms, newCorridor, state[2] + stepCount * 10 ** newRooms[roomIndex][roomSpotIndex])

def moveFromCorridorIntoRoom(state: State) -> Iterable[State]:
    """Moves any suitable amphipod in the corridor into the corresponding rooms."""
    for roomIndex, room in enumerate(state[0]):
        # If the room is in an invalid condition (wrong amphipods or holes between amphipods),
        # then we can skip this room, it has to be cleared first.
        if not isRoomInValidCondition(room, roomIndex): continue
        # Look for the largest free spot in the room (may be None if room is full).
        roomSpotIndex = reduce(
            lambda index, roomSpotIndex: roomSpotIndex if room[roomSpotIndex] is None else index,
            range(len(room)),
            None,
        )
        if roomSpotIndex is not None:
            # There is a free spot in this room, attempt to move amphipods here.
            newRooms = deepcopy(state[0])
            newRooms[roomIndex][roomSpotIndex] = roomIndex
            for corridorLeftSideState in moveFromCorridorLeftSideIntoRoom(state, roomIndex, roomSpotIndex, newRooms):
                yield corridorLeftSideState
            for corridorRightSideState in moveFromCorridorRightSideIntoRoom(state, roomIndex, roomSpotIndex, newRooms):
                yield corridorRightSideState

def moveAmphipods(state: State) -> Iterable[State]:
    """Performs any actions available in the given state: Moving into the corridor or rooms."""
    for roomIntoCorridorState in moveFromRoomIntoCorridor(state):
        yield roomIntoCorridorState
    for corridorIntoRoomState in moveFromCorridorIntoRoom(state):
        yield corridorIntoRoomState

def findLowestAmphipodEnergyUse(initialState: State) -> int:
    """Finds the lowest amount of energy used for any solution from the given initial state."""
    # The same amphipod layout can be reached in many ways. To ensure we don't waste time
    # visiting states we have already encountered, we keep track of the states and the energy
    # level we reached them at. This way, only if we reach the same state at a lower energy
    # level will we consider it again.
    encounteredStates = dict()
    currentLowestEnergyUsed = maxsize
    # Start by adding only the initial state to the queue.
    stateQueue = deque([initialState])
    while len(stateQueue):
        # Take the next state from the queue (breadth-first).
        state = stateQueue.popleft()
        hashableState = tuple(list(chain.from_iterable(state[0])) + state[1])
        # If we have seen this state before with a better energy level, we don't have to check it again.
        if hashableState in encounteredStates and encounteredStates[hashableState] <= state[2]: continue
        # Otherwise, store the new state or update its energy level to the better one.
        encounteredStates[hashableState] = state[2]
        if areAllRoomsSolved(state[0]):
            # Update the energy value if the state has all amphipods in the right spots.
            currentLowestEnergyUsed = min(currentLowestEnergyUsed, state[2])
        else:
            # Otherwise, add all the following states to the queue.
            stateQueue.extend(moveAmphipods(state))
    return currentLowestEnergyUsed

initialState1 = (
    # Rooms
    [
        [2, 1],
        [1, 2],
        [0, 3],
        [3, 0],
    ],
    # Corridor
    [None] * 7,
    # Used Energy
    0
)
print(f'2021-12-23 Part 1: {findLowestAmphipodEnergyUse(initialState1)}')

# Clone the first initial state and insert more spots in the rooms.
initialState2 = deepcopy(initialState1)
initialState2[0][0][1:1] = [3, 3]
initialState2[0][1][1:1] = [2, 1]
initialState2[0][2][1:1] = [1, 0]
initialState2[0][3][1:1] = [0, 2]
print(f'2021-12-23 Part 2: {findLowestAmphipodEnergyUse(initialState2)}')