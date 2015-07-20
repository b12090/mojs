h          = mojs.h
PathEasing = mojs.easing.PathEasing

describe 'PathEasing ->', ->
  it 'should be a function', ->
    expect(typeof mojs.easing.PathEasing).toBe 'function'
  it 'should not init if "creator" was passed', ->
    pe = new PathEasing 'creator'
    expect(pe.precision).not.toBeDefined()

  it 'should have path property', ->
    pe = new PathEasing 'creator'
    easing = pe.create 'M 0, 0 L 100,100'
    expect(easing.path instanceof SVGElement).toBe true


  describe 'variables ->', ->
    it 'should have _eps defined', ->
      pe = new PathEasing 'M0,0 L10,10'
      expect(pe._eps).toBeDefined()
    it 'should have _eps defined', ->
      pe = new PathEasing 'M0,0 L10,10'
      expect(pe._precompute).toBe 2000
      expect(pe._step).toBe       1/pe._precompute
    it 'should have _boundsPrevProgress defined', ->
      pe = new PathEasing 'M0,0 L10,10'
      expect(pe._boundsPrevProgress).toBe -1

  describe 'path parsing ->', ->
    it 'should parse path', ->
      path = 'M0,0 L10,10'
      spyOn h, 'parsePath'
      pe = new PathEasing path
      expect(h.parsePath).toHaveBeenCalledWith path
    it 'should save path and pathLength', ->
      path = 'M0,0 L10,10'
      pe = new PathEasing path
      expect(pe.path).toBeDefined()
      expect(pe.pathLength).toBe pe.path.getTotalLength()
    it 'should error if path wasnt parsed', ->
      path = 'M0,0 L10,10'
      spyOn h, 'error'
      spyOn h, 'parsePath' # spoil the parsePath method
      pe = new PathEasing path
      expect(h.error).toHaveBeenCalled()

  describe 'options ->', ->
    it 'should recieve "_approximateMax" option', ->
      path = 'M0,0 L10,10'
      pe = new PathEasing path, approximateMax: 10
      expect(pe._approximateMax).toBe 10
    it 'should recieve "rect" option', ->
      path = 'M0,0 L10,10'
      pe = new PathEasing path, rect: 200
      expect(pe._rect).toBe 200
    it 'should recieve "eps" option', ->
      path = 'M0,0 L10,10'
      eps = .00001
      pe = new PathEasing path, eps: eps
      expect(pe._eps).toBe eps
    
    describe 'precompute option ->', ->
      it 'should recieve "precompute" option', ->
        path = 'M0,0 L10,10'
        precompute = 10000
        pe = new PathEasing path, precompute: precompute
        expect(pe._precompute).toBe precompute
      it 'should not be larger than 10000', ->
        path = 'M0,0 L10,10'
        precompute = 20000
        pe = new PathEasing path, precompute: precompute
        expect(pe._precompute).toBe 10000
      it 'should not be smaller than 100', ->
        path = 'M0,0 L10,10'
        precompute = 20
        pe = new PathEasing path, precompute: precompute
        expect(pe._precompute).toBe 100

  describe '_preSample method ->', ->
    it 'should pre sample the path', ->
      pe = new PathEasing 'M0,100 100,0'
      len = pe.pathLength
      expect(pe._samples[0]).toBeDefined()
      expect(pe._samples[1]).toBeDefined()
      expect(pe._samples[2]).toBeDefined()
      expect(pe._samples[50]).toBeDefined()
      expect(pe._samples[pe._precompute-1]).toBeDefined()

  describe 'sample method ->', ->
    it 'should clamp x value', ->
      path = 'M0,100 100,0'
      pe = new PathEasing path
      expect(pe.sample(-.5)).toBeCloseTo 0, 3
      expect(pe.sample(1.5)).toBeCloseTo 1, 2
    it 'should return y', ->
      path = 'M0,100 100,0'
      pe = new PathEasing path
      expect(Math.abs(pe.sample(.7) - .7)).toBeLessThan pe._eps
    it 'should sample y', ->
      pe = new PathEasing 'M0,100 100,0'
      for i in [1...20]
        progress = 1/i
        expect(Math.abs(pe.sample(progress) - progress)).toBeLessThan pe._eps
    it 'should call _findApproximate method if bounds are not close enough',->
      pe = new PathEasing 'M0,100 100,0', precompute: 100
      spyOn pe, '_findApproximate'
      pe.sample(0.015)
      expect(pe._findApproximate).toHaveBeenCalled()

  describe '_checkIfBoundsCloseEnough method', ->
    it 'should return start value if it is close enough', ->
      pe = new PathEasing 'M0,100 100,0'
      value = .5
      pe._checkIfBoundsCloseEnough(value, {
        start: {point: {x: value+(pe._eps/2)}},
        end:   {point: {x: .75}}
        })
    it 'should return end value if it is close enough', ->
      pe = new PathEasing 'M0,100 100,0'
      value = .5
      pe._checkIfBoundsCloseEnough(value, {
        start: {point: {x: .25}},
        end:   {point: {x: value+(pe._eps/2)}}
        })

  describe '_approximate method',->
    it 'should find approximation', ->
      pe = new PathEasing 'M0,100 100,0'
      s = pe._samples
      approximation = pe._approximate s[11], s[12], s[11].progress+0.0003
      point1 = pe.path.getPointAtLength approximation
      length2 = s[11].length + .3*(s[12].length - s[11].length)
      point2 = pe.path.getPointAtLength length2
      expect(point1.x).toBeCloseTo point2.x, 1
  describe '_findApproximate method',->
    it 'should return y', ->
      pe1 = new PathEasing 'M0,100 100,0'
      p = 0.203231
      bounds = pe1._findBounds pe1._samples, p
      value = pe1._findApproximate p, bounds.start, bounds.end
      expect(value).toBeCloseTo p, 4
    it 'should stop if running for a log time( _approximateMax < 1)', ->
      pe1 = new PathEasing 'M0,100 100,0', precompute: 100
      p = 0.015
      start = {point: {x: 0.01}, length: 0}
      end   = {point: {x: 0.02}, length: 1}
      spyOn(pe1, '_findApproximate').and.callThrough()
      value = pe1._findApproximate p, start, end, 1
      expect(pe1._findApproximate.calls.count()).toBe 1


    it 'should call self recursivelly if not precise enough
        but no more then _approximateMax value', ->
      pe = new PathEasing 'M0,100 100,0', precompute: 100, eps: .00000001
      p = 0.015
      start = {point: {x: 0.01}, length: 10}
      end   = {point: {x: 0.5}, length: 20}
      spyOn(pe, '_findApproximate').and.callThrough()
      value = pe._findApproximate p, start, end
      expect(pe._findApproximate.calls.count()).toEqual 5

  describe '_findBounds method', ->
    it 'should find lowest and highest bounderies',->
      pe1 = new PathEasing 'M0,100 100,0'
      progress = .735
      bounds = pe1._findBounds pe1._samples, progress
    it 'should save previous start index', ->
      pe1 = new PathEasing 'M0,100 100,0'
      progress = .735
      bounds = pe1._findBounds pe1._samples, progress
      expect(pe1._boundsStartIndex).toBeGreaterThan 1400
      expect(pe1._boundsPrevProgress).toBe .735
    it 'should return [0] item if progress is 0', ->
      pe1 = new PathEasing 'M0,100 100,0'
      progress = 0
      bounds = pe1._findBounds pe1._samples, progress
      expect(bounds.start).toBeDefined()
      expect(bounds.start.point.x).toBeCloseTo 0, 1
    it 'should cache index in reverse order', ->
      pe1 = new PathEasing 'M0,100 100,0'
      progress = .735; newProgress = progress - .2
      bounds = pe1._findBounds pe1._samples, progress
      bounds = pe1._findBounds pe1._samples, newProgress
      expect(pe1._boundsStartIndex).toBeLessThan 1400
      expect(pe1._boundsPrevProgress).toBe newProgress
    it 'should cache previous return object', ->
      pe1 = new PathEasing 'M0,100 100,0'
      bounds = pe1._findBounds pe1._samples, .735
      expect(pe1._prevBounds).toBe bounds
    it 'should detect if previous progress is the current one', ->
      pe1 = new PathEasing 'M0,100 100,0'
      progress = .735; newProgress = progress - .2
      bounds1 = pe1._findBounds pe1._samples, progress
      bounds2 = pe1._findBounds pe1._samples, progress
      expect(bounds1).toBe bounds2

  describe '_resolveY method', ->
    it 'should resolve Y from point', ->
      pe1 = new PathEasing('M0,100 100,0'); y = 10
      expect(pe1._resolveY(y: y)).toBe 1-(y/100)

  describe 'create method ->', ->
    it 'should create new instance of path-easing and return it\'s method', ->
      pe = new PathEasing 'creator'
      easing = pe.create('M0,100 100,0', precision: 10)
      expect(typeof easing).toBe 'function'
      expect(Math.abs(easing(.5)-.5)).toBeLessThan .01


  # describe '_normalizePath method', ->
  #   it 'should normalize start x value to 0', ->
  #     pe = new PathEasing 'creator'
  #     newPath = pe._normalizePath('M0.1,0 L100,100')
  #     expect(newPath).toBe 'M0,0 L100,100'

  #   it 'should normalize end x value to rect.x value', ->
  #     pe = new PathEasing 'creator'
  #     newPath = pe._normalizePath('M0.1,0 L99,100')
  #     expect(newPath).toBe 'M0,0 L100,100'

  #   it 'should normalize end x value for the latest segment only', ->
  #     pe = new PathEasing 'creator'
  #     pe.isIt = true
  #     path = 'M0.1,0 C68,-3.5 69,6 70,14 C70,21 74,27 74,18 C77,-0.6 100,0 101,0 Z'
  #     newPath = pe._normalizePath(path)
  #     normPath = 'M0,0 C68,-3.5 69,6 70,14 C70,21 74,27 74,18 C77,-0.6 100,0 101,0 Z'
  #     expect(newPath).toBe normPath

  describe '_normalizeSegment method', ->
    it 'should normalize segment by passed value', ->
      pe = new PathEasing 'creator'
      expect(pe._normalizeSegment('0.1522, 100 ', 0)).toBe '0, 100'

  describe '_getSegmentPairs', ->
    it 'should normalize an array by pairs', ->
      pe = new PathEasing 'creator'
      pairs = pe._getSegmentPairs(['0.12', '102'])
      expect(pairs[0][0]).toBe '0.12'
      expect(pairs[0][1]).toBe '102'
      pairs = pe._getSegmentPairs(['0.12', '102', 200, 12])
      expect(pairs[0][0]).toBe '0.12'
      expect(pairs[0][1]).toBe '102'
      expect(pairs[1][0]).toBe 200
      expect(pairs[1][1]).toBe 12

    it 'should error if array is not even', ->
      pe = new PathEasing 'creator'
      spyOn h, 'error'
      pairs = pe._getSegmentPairs(['0.12', '102', 200])
      expect(h.error).toHaveBeenCalled()



    




