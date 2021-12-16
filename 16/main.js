const hexInput = '420D4900B8F31EFE7BD9DA455401AB80021504A2745E1007A21C1C862801F54AD0765BE833D8B9F4CE8564B9BE6C5CC011E00D5C001098F11A232080391521E4799FC5BB3EE1A8C010A00AE256F4963B33391DEE57DA748F5DCC011D00461A4FDC823C900659387DA00A49F5226A54EC378615002A47B364921C201236803349B856119B34C76BD8FB50B6C266EACE400424883880513B62687F38A13BCBEF127782A600B7002A923D4F959A0C94F740A969D0B4C016D00540010B8B70E226080331961C411950F3004F001579BA884DD45A59B40005D8362011C7198C4D0A4B8F73F3348AE40183CC7C86C017997F9BC6A35C220001BD367D08080287914B984D9A46932699675006A702E4E3BCF9EA5EE32600ACBEADC1CD00466446644A6FBC82F9002B734331D261F08020192459B24937D9664200B427963801A094A41CE529075200D5F4013988529EF82CEFED3699F469C8717E6675466007FE67BE815C9E84E2F300257224B256139A9E73637700B6334C63719E71D689B5F91F7BFF9F6EE33D5D72BE210013BCC01882111E31980391423FC4920042E39C7282E4028480021111E1BC6310066374638B200085C2C8DB05540119D229323700924BE0F3F1B527D89E4DB14AD253BFC30C01391F815002A539BA9C4BADB80152692A012CDCF20F35FDF635A9CCC71F261A080356B00565674FBE4ACE9F7C95EC19080371A009025B59BE05E5B59BE04E69322310020724FD3832401D14B4A34D1FE80233578CD224B9181F4C729E97508C017E005F2569D1D92D894BFE76FAC4C5FDDBA990097B2FBF704B40111006A1FC43898200E419859079C00C7003900B8D1002100A49700340090A40216CC00F1002900688201775400A3002C8040B50035802CC60087CC00E1002A4F35815900903285B401AA880391E61144C0004363445583A200CC2C939D3D1A41C66EC40';

const bitStream = hexInput.split('').flatMap(hexChar => `${parseInt(hexChar, 16).toString(2)}`.padStart(4, '0').split(''));

const readNumber = (bitStream, length, asString) => (asString ? s => s : parseInt)(bitStream.splice(0, length).join(''), 2);

const parsePacket = bitStream => {
    const [ version, type ] = [ readNumber(bitStream, 3), readNumber(bitStream, 3) ];
    if (type === 4) {
        let [ nextFlag, number ] = [ 0, '' ];
        do {
            [ nextFlag, number ] = [ readNumber(bitStream, 1), number + readNumber(bitStream, 4, true) ];
        } while (nextFlag);
        return { version, number: parseInt(number, 2) };
    } else if (readNumber(bitStream, 1)) {
        const packets = [ ...Array(readNumber(bitStream, 11)) ].map(_ => parsePacket(bitStream));
        return { version, type, packets };
    }
    const [ innerBitStream, packets ] = [ bitStream.splice(0, readNumber(bitStream, 15)), [] ];
    while (innerBitStream.length) packets.push(parsePacket(innerBitStream));
    return { version, type, packets };
};

const sumVersions = packet =>
    typeof packet.number === 'number' ? packet.version :
    packet.packets.reduce((sum, packet) => sum + sumVersions(packet), packet.version);

const evaluatePacket = packet =>
    typeof packet.number === 'number' ? packet.number :
    packet.type === 0 ? packet.packets.reduce((sum, packet) => sum + evaluatePacket(packet), 0) :
    packet.type === 1 ? packet.packets.reduce((prod, packet) => prod * evaluatePacket(packet), 1) :
    packet.type === 2 ? packet.packets.reduce((min, packet) => Math.min(min, evaluatePacket(packet)), Number.MAX_VALUE) :
    packet.type === 3 ? packet.packets.reduce((max, packet) => Math.max(max, evaluatePacket(packet)), Number.MIN_VALUE) :
    packet.type === 5 ? +(evaluatePacket(packet.packets[0]) > evaluatePacket(packet.packets[1])) :
    packet.type === 6 ? +(evaluatePacket(packet.packets[0]) < evaluatePacket(packet.packets[1])) :
    +(evaluatePacket(packet.packets[0]) === evaluatePacket(packet.packets[1]));

const packet = parsePacket(bitStream);
console.log(`2021-12-16 Part 1: ${sumVersions(packet)}`);
console.log(`2021-12-16 Part 2: ${evaluatePacket(packet)}`);