energy_levels = [
    6 2 2 7 6 1 8 5 3 6
    2 3 6 8 1 5 8 3 8 4
    5 3 8 5 4 1 4 1 1 3
    4 5 5 6 7 5 7 5 2 3
    6 7 4 6 4 8 6 7 2 4
    4 8 8 1 3 2 3 8 8 4
    4 6 4 8 2 6 3 7 4 4
    4 8 7 1 3 3 2 8 7 2
    4 7 2 4 1 2 8 2 2 8
    4 3 1 6 5 1 2 1 6 7
]

flash_tracker = zeros(Bool, size(energy_levels))

function process_flashes!(energy_levels, flash_tracker)
    for i = 1:size(energy_levels, 1), j = 1:size(energy_levels, 2)
        if !flash_tracker[i, j] && energy_levels[i, j] > 9
            flash_tracker[i, j] = true
            energy_levels[
                max(1, i - 1):min(size(energy_levels, 1), i + 1),
                max(1, j - 1):min(size(energy_levels, 2), j + 1)
            ] .+= 1
            process_flashes!(energy_levels, flash_tracker)
        end
    end
end

step_count = flash_count = 0
while prod(flash_tracker) == 0
    global step_count += 1
    energy_levels[flash_tracker] .= 0
    fill!(flash_tracker, 0)
    energy_levels .+= 1
    process_flashes!(energy_levels, flash_tracker)
    global flash_count += sum(flash_tracker)
    if step_count == 100
        println("2021-12-11 Part 1: $flash_count")
    end
end
println("2021-12-11 Part 2: $step_count")