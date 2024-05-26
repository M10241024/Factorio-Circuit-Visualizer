
local Queue = {}

function Queue.new()
    return {
        queue = {},
        id_map = {},
        first = 0,
        last = -1,
    }
end

function Queue:clear()
    self.queue = {}
    self.id_map = {}
    self.first = 0
    self.last = -1
end

function Queue:get_length()
    local length = self.last - self.first  + 1
    if length == 0 then
        Queue.clear(self)
    end
    return length
end

function Queue:is_empty()
    if self.last + 1 == self.first then
        Queue.clear(self)
        return true
    end
    return false
end

function Queue:push(item, id)
    if not self.id_map[id] then
        self.id_map[id] = item
        self.last = self.last + 1
        self.queue[self.last] = id
        return true
    end
    return false
end

function Queue:pop()
    local result_id = self.queue[self.first]
    if result_id then
        self.queue[self.first] = nil
        self.first = self.first + 1
        local result = self.id_map[result_id]
        self.id_map[result] = nil
        Queue.is_empty(self)
        return result
    end
    return nil
end

return Queue
