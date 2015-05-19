video_pooling_deepcaffe('trecvidmed10', 'keyframe-100000', 'devel')
video_pooling_deepcaffe('trecvidmed10', 'keyframe-100000', 'test')

>> gen_sge_code('densetraj_encode_sge', 'trecvidmed10 keyframe-100000 devel %d %d', 1742, 200)
>> gen_sge_code('densetraj_encode_sge', 'trecvidmed10 keyframe-100000 test %d %d', 1720, 200) 

