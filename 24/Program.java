import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;
import java.util.function.Supplier;
import java.util.stream.LongStream;

class Program {
    public static void main(String[] args) throws IOException {
        var program = readAllCommands();
        Supplier<LongStream> inputs = () -> LongStream.rangeClosed(1L, 9L);
        
        // To find the largest model number, crack with increasing input numbers.
        var largestModelNumber = crackTheMonad(program, inputs.get().toArray(), 0, MonadState.initial());
        System.out.println(String.format("2021-12-24 Part 1: %s", largestModelNumber));

        // To find the smallest model number, crack with decreasing input numbers.
        var smallestModelNumber = crackTheMonad(program, inputs.get().map(i -> 10L - i).toArray(), 0, MonadState.initial());
        System.out.println(String.format("2021-12-24 Part 2: %s", smallestModelNumber));
    }

    /** Read and parse all commands contained in the input file. */
    static List<ICommand> readAllCommands() throws IOException {
        try (var reader = new BufferedReader(new FileReader("input.txt"))) {
            var commands = new ArrayList<ICommand>();
            String line;
            while ((line = reader.readLine()) != null) {
                commands.add(parseCommand(line));
            }
            return commands;
        }
    }

    /** Parse a single input file line and return the command. */
    static ICommand parseCommand(String inputLine) {
        var parts = inputLine.split(" ");
        var command = InputCommand.parse(parts);
        return command == null ? BinaryCommand.parse(parts) : command;
    }

    /** Executes the given program from the command at the start index to before the end index. */
    static void executeProgram(List<ICommand> program, CommandContext context, int startIndex, int endIndex) {
        for (var index = startIndex; index < endIndex; program.get(index++).execute(context));
    }

    /** Locate all "inp" command indexes in the given program, including index after the program. */
    static List<Integer> findInputCommandLocations(List<ICommand> program) {
        var inputCommandLocations = new ArrayList<Integer>();
        for (var index = 0; index < program.size(); index++) {
            if (program.get(index) instanceof InputCommand) {
                inputCommandLocations.add(index);
            }
        }
        inputCommandLocations.add(program.size());
        return inputCommandLocations;
    }

    /** Run the MONAD program using the given input sequence, one "inp" block at a time. */
    static String crackTheMonad(List<ICommand> program, long[] inputs, int block, Collection<MonadState> states) {
        var inputCommandLocations = findInputCommandLocations(program);
        var nextStates = new HashMap<Long, MonadState>();
        // The order of the inputs determines what solution will be found:
        // If the inputs are ascending, the same zValues found later - with higher input value - will have priority.
        // If the inputs are descending, the same zValues found later - with lower input value - will have priority.
        // This means the first case will return the largest model number, the second one the smallest.
        for (var input : inputs) {
            for (var state : states) {
                var context = new CommandContext(state.zValue(), input);
                executeProgram(program, context, inputCommandLocations.get(block), inputCommandLocations.get(block + 1));
                // Do not include unreasonably large zValues in the calculation.
                if (context.variables()[3] <= 1000000L) {
                    nextStates.put(context.variables()[3], state.withInput(context.variables()[3], input));
                }
            }
        }
        // If we're at the last input block, the solution can be read from the newly calculated states.
        if (block == inputCommandLocations.size() - 2) {
            var builder = new StringBuilder();
            for (var input : nextStates.get(0L).inputs()) {
                builder.append(input.toString());
            }
            return builder.toString();
        }
        return crackTheMonad(program, inputs, block + 1, nextStates.values());
    }
}

record MonadState(
    long zValue,
    List<Long> inputs
) {
    public static Collection<MonadState> initial() {
        return new ArrayList<MonadState>(Arrays.asList(new MonadState(0L, new ArrayList<Long>())));
    }

    public MonadState withInput(long zValue, long input) {
        var updatedInputs = new ArrayList<Long>(inputs);
        updatedInputs.add(input);
        return new MonadState(zValue, updatedInputs);
    }
}

record CommandContext(
    long[] variables,
    long input
) {
    public CommandContext(long zValue, long input) {
        this(new long[] { 0L, 0L, 0L, zValue }, input);
    }

    static int parseVariable(String variable) {
        return variable.charAt(0) - 'w';
    }

    static Long parseNumber(String number) {
        try {
            return Long.parseLong(number);
        } catch (Exception ex) {
            return null;
        }
    }
}

interface ICommand {
    void execute(CommandContext context);
}

record InputCommand(
    int inputVariable
) implements ICommand {
    public void execute(CommandContext context) {
        context.variables()[inputVariable] = context.input();
    }

    public static ICommand parse(String[] parts) {
        return parts[0].equals("inp") ?
            new InputCommand(
                CommandContext.parseVariable(parts[1])
            ) : null;
    }
}

record BinaryCommand(
    int targetVariable,
    int sourceVariable,
    Long sourceNumber,
    BiFunction<Long, Long, Long> command
) implements ICommand {
    public void execute(CommandContext context) {
        context.variables()[targetVariable] = command.apply(
            context.variables()[targetVariable],
            sourceNumber == null ? context.variables()[sourceVariable] : sourceNumber
        );
    }

    static Map<String, BiFunction<Long, Long, Long>> commands = Map.of(
        "add", (a, b) -> a + b,
        "mul", (a, b) -> a * b,
        "div", (a, b) -> a / b,
        "mod", (a, b) -> a % b,
        "eql", (a, b) -> a == b ? 1L : 0L
    );

    public static ICommand parse(String[] parts) {
        return new BinaryCommand(
            CommandContext.parseVariable(parts[1]),
            CommandContext.parseVariable(parts[2]),
            CommandContext.parseNumber(parts[2]),
            commands.get(parts[0])
        );
    }
}