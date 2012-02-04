describe "Joosy.Resource.Collection", ->

  class Test extends Joosy.Resource.Generic
    @entity 'test'

  data = '[{"id": 1, "name": "test1"}, {"id": 2, "name": "test2"}]'

  checkData = (collection) ->
    expect(collection.data.length).toEqual 2
    expect(collection.pages[1]).toEqual collection.data
    expect(collection.data[0].constructor == Test).toBeTruthy()
    expect(collection.data[0].e.name).toEqual 'test1'

  beforeEach ->
    @collection = new Joosy.Resource.RESTCollection(Test)

  it "should initialize", ->
    expect(@collection.model).toEqual Test
    expect(@collection.params).toEqual Object.extended()
    expect(@collection.data).toEqual []

  it "should modelize", ->
    result = @collection.modelize $.parseJSON(data)
    expect(result[0].constructor == Test).toBeTruthy()
    expect(result[0].e.name).toEqual 'test1'

  it "should reset", ->
    @collection.reset $.parseJSON(data)
    checkData @collection
  
  it "should trigger changes", ->
    @collection.bind 'changed', callback = sinon.spy()
    @collection.reset $.parseJSON(data)
    expect(callback.callCount).toEqual 1